//
//  Zlevo.m
//  MZlevoclient
//
//  Created by iBcker on 13-5-8.
//  Copyright (c) 2013年 iBcker. All rights reserved.
//

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>



#import "LevoConnet.h"
#import "PreferencesModel.h"

#import <pcap.h>
#import <stdio.h>
#import <stdlib.h>
#import <stdint.h>

#import <string.h>
#import <ctype.h>
#import <errno.h>

#import <sys/types.h>
#import <sys/socket.h>
#import <sys/ioctl.h>
#import <sys/stat.h>

#import <netinet/in.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <net/ethernet.h>

//------bsd/apple mac
#import <net/if_var.h>
#import <net/if_dl.h>
#import <net/if_types.h>

#import <getopt.h>
#import <iconv.h>
#import <signal.h>
#import <unistd.h>
#import <fcntl.h>
#import <assert.h>

#import "md5.h"


int bsd_get_mac(const char ifname[], uint8_t eth_addr[]);

/* ZlevoClient Version */
#define LENOVO_VER "1.0"

/* default snap length (maximum bytes per packet to capture) */
#define SNAP_LEN 1518

/* ethernet headers are always exactly 14 bytes [1] */
#define SIZE_ETHERNET 14

#define LOCKFILE "/var/run/aLevoClient.pid"

#define KEEP_ALIVE_TIME 60

#define LOCKMODE (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)

/* Ethernet header */
struct sniff_ethernet {
    u_char  ether_dhost[ETHER_ADDR_LEN];    /* destination host address */
    u_char  ether_shost[ETHER_ADDR_LEN];    /* source host address */
    u_short ether_type;                     /* IP? ARP? RARP? etc */
};

struct sniff_eap_header {
    u_char eapol_v;
    u_char eapol_t;
    u_short eapol_length;
    u_char eap_t;
    u_char eap_id;
    u_short eap_length;
    u_char eap_op;
    u_char eap_v_length;
    u_char eap_info_tailer[100];
};

struct follow {
	uint32_t	inBytes;	//进包
	uint32_t 	outBytes;	//出包
    struct timeval time ;
};

enum EAPType {
    EAPOL_START,
    EAPOL_LOGOFF,
    EAP_REQUEST_IDENTITY,
    EAP_RESPONSE_IDENTITY,
    EAP_REQUEST_IDENTITY_KEEP_ALIVE,
    EAP_RESPONSE_IDENTITY_KEEP_ALIVE,
    EAP_REQUETS_MD5_CHALLENGE,
    EAP_RESPONSE_MD5_CHALLENGE,
    EAP_SUCCESS,
    EAP_FAILURE,
    ERROR
};

enum STATE {
    READY,
    STARTED,
    ID_AUTHED,
    ONLINE
};

void    send_eap_packet(enum EAPType send_type);
char*   get_md5_digest(const char* str, size_t len);
void    action_by_eap_type(enum EAPType pType,
                           const struct sniff_eap_header *header);
void    init_frames();
void    init_info();
void    init_device();
int     set_device_new_ip();
void    fill_password_md5(u_char *attach_key, u_int id);
int     program_running_check();
void   keep_alive();
int     code_convert(char *from_charset, char *to_charset,
                     char *inbuf, size_t inlen, char *outbuf, size_t outlen);
void    print_server_info (const u_char *str);

static void signal_interrupted (int signo);
static void get_packet(u_char *args, const struct pcap_pkthdr *header,
                       const u_char *packet);

u_char talier_eapol_start[] = {0x00, 0x00, 0x2f, 0xfc, 0x03, 0x00};
u_char talier_eap_md5_resp[] = {0x00, 0x00, 0x2f, 0xfc, 0x00, 0x03, 0x01, 0x01, 0x00};

/* #####   GLOBLE VAR DEFINITIONS   ######################### */
/*-----------------------------------------------------------------------------
 *  程序的主控制变量
 *-----------------------------------------------------------------------------*/
int         lockfile;
char        errbuf[PCAP_ERRBUF_SIZE];  /* error buffer */
enum STATE  state = READY;                     /* program state */
pcap_t      *handle = NULL;			   /* packet capture handle */
u_char      muticast_mac[] =            /* 802.1x的认证服务器多播地址 */
{0x01, 0x80, 0xc2, 0x00, 0x00, 0x03};


/* #####   GLOBLE VAR DEFINITIONS   ###################
 *-----------------------------------------------------------------------------
 *  用户信息的赋值变量，由init_argument函数初始化
 *-----------------------------------------------------------------------------*/
int         background = 0;            /* 后台运行标记  */
char        *dev = NULL;               /* 连接的设备名 */
char        *username = NULL;
char        *password = NULL;
int         exit_flag = 0;
int         debug_on = 0;
/* #####   GLOBLE VAR DEFINITIONS   #########################
 *-----------------------------------------------------------------------------
 *  报文相关信息变量，由init_info 、init_device函数初始化。
 *-----------------------------------------------------------------------------*/
int         username_length;
int         password_length;
u_int       local_ip = 0;
u_char      local_mac[ETHER_ADDR_LEN]; /* MAC地址 */
char        dev_if_name[64];

/* #####   TYPE DEFINITIONS   ######################### */
/*-----------------------------------------------------------------------------
 *  报文缓冲区，由init_frame函数初始化。
 *-----------------------------------------------------------------------------*/
u_char      eapol_start[64];            /* EAPOL START报文 */
u_char      eapol_logoff[64];           /* EAPOL LogOff报文 */
u_char      eapol_keepalive[64];
u_char      eap_response_ident[128]; /* EAP RESPON/IDENTITY报文 */
u_char      eap_response_md5ch[128]; /* EAP RESPON/MD5 报文 */


//u_int       live_count = 0;             /* KEEP ALIVE 报文的计数值 */
//pid_t       current_pid = 0;            /* 记录后台进程的pid */

PreferencesModel *config;

void(^ConnetSucessBlock)(void);
void(^ConnetFailBlock)(void);


@implementation LevoConnet

IMP_SINGLETON(LevoConnet)


- (id)init
{
    if(self=[super init]){
        config=[PreferencesModel sharedInstance];
    }
    return self;
}

// debug function
void
print_hex(const uint8_t *array, int count)
{
    int i;
    for(i = 0; i < count; i++){
        if ( !(i % 16))
            printf ("\n");
        printf("%02x ", array[i]);
    }
    printf("\n");
}

int
code_convert(char *from_charset, char *to_charset,
             char *inbuf, size_t inlen, char *outbuf, size_t outlen)
{
    iconv_t cd;
    char **pin = &inbuf;
    char **pout = &outbuf;
    
    cd = iconv_open(to_charset,from_charset);
    
    if (cd==0)
        return -1;
    memset(outbuf,0,outlen);
    
    if (iconv(cd, pin, &inlen, pout, &outlen)==-1)
        return -1;
    iconv_close(cd);
    return 0;
}

void
print_server_info (const u_char *str)
{
    if (!(str[0] == 0x2f && str[1] == 0xfc))
        return;
    
    char info_str [1024] = {0};
    int length = str[2];
    if (code_convert ("gb2312", "utf-8", (char*)str + 3, length, info_str, 200) != 0){
        fprintf (stderr, "@@Error: Server info convert error.\n");
        return;
    }
    [[PreferencesModel sharedInstance] pushLog:[NSString stringWithUTF8String:info_str]];
    fprintf (stdout, "&&Server Info: %s\n", info_str);
}

/*
 * ===  FUNCTION  ======================================================================
 *         Name:  get_md5_digest
 *  Description:  calcuate for md5 digest
 * =====================================================================================
 */
char*
get_md5_digest(const char* str, size_t len)
{
    static md5_byte_t digest[16];
	md5_state_t state;
	md5_init(&state);
	md5_append(&state, (const md5_byte_t *)str, (int)len);
	md5_finish(&state, digest);
    
    return (char*)digest;
}


enum EAPType
get_eap_type(const struct sniff_eap_header *eap_header)
{
    switch (eap_header->eap_t){
        case 0x01:
            if (eap_header->eap_op == 0x01)
                return EAP_REQUEST_IDENTITY;
            if (eap_header->eap_op == 0x04)
                return EAP_REQUETS_MD5_CHALLENGE;
            break;
        case 0x03:
            //    if (eap_header->eap_id == 0x02)
            return EAP_SUCCESS;
            break;
        case 0x04:
            return EAP_FAILURE;
    }
    fprintf (stderr, "&&IMPORTANT: Unknown Package : eap_t:      %02x\n"
             "                               eap_id: %02x\n"
             "                               eap_op:     %02x\n",
             eap_header->eap_t, eap_header->eap_id,
             eap_header->eap_op);
    return ERROR;
}

void
action_by_eap_type(enum EAPType pType,
                   const struct sniff_eap_header *header) {
    //    printf("PackType: %d\n", pType);
    switch(pType){
        case EAP_SUCCESS:
            state = ONLINE;
//            [[PreferencesModel sharedInstance] pushLog:@"EAP验证成功"];
            fprintf(stdout, ">>Protocol: EAP_SUCCESS\n");
            fprintf(stdout, "&&Info: Authorized Access to Network. \n");
            keep_alive();
            ConnetSucessBlock();
            config.connetState=ConnetStateOnline;
            /* Set alarm to send keep alive packet */
            break;
        case EAP_FAILURE:
            if (state == READY) {
//                [[PreferencesModel sharedInstance] pushLog:@"..."];
                fprintf(stdout, ">>Protocol: Init Logoff Signal\n");
                return;
            }
            fprintf(stdout, ">>Protocol: EAP_FAILURE\n");
            [[PreferencesModel sharedInstance] pushLog:@"EAP验证失败"];
//            if(state == ONLINE){
//                fprintf(stdout, "&&Info: SERVER Forced Logoff\n");
//                [[PreferencesModel sharedInstance] pushLog:@"SERVER Forced Logoff"];
//            }
//            if (state == STARTED){
//                [[PreferencesModel sharedInstance] pushLog:@"用户名错误"];
//                fprintf(stdout, "&&Info: Invalid Username or Client info mismatch.\n");
//            }
//            if (state == ID_AUTHED){
//                [[PreferencesModel sharedInstance] pushLog:@"密码错误"];
//                fprintf(stdout, "&&Info: Invalid Password.\n");
//            }
            print_server_info (header->eap_info_tailer);
            state = READY;
            if (handle) {
                pcap_breakloop (handle);
            }
            break;
        case EAP_REQUEST_IDENTITY:
            fprintf(stdout, ">>Protocol: REQUEST EAP-Identity\n");
            memset (eap_response_ident + 14 + 5, header->eap_id, 1);
            send_eap_packet(EAP_RESPONSE_IDENTITY);
            [[PreferencesModel sharedInstance] pushLog:@"发送EAP-Identity..."];
            break;
        case EAP_REQUETS_MD5_CHALLENGE:
            state = ID_AUTHED;
            fprintf(stdout, ">>Protocol: REQUEST MD5-Challenge(PASSWORD)\n");
            fill_password_md5((u_char*)header->eap_info_tailer,
                              header->eap_id);
            send_eap_packet(EAP_RESPONSE_MD5_CHALLENGE);
            [[PreferencesModel sharedInstance] pushLog:@"发送MD5-Challenge(PASSWORD)..."];
            break;
        default:
            NSLog(@"未知报文");
            print_server_info (header->eap_info_tailer);
            return;
    }
}

void
send_eap_packet(enum EAPType send_type)
{
    u_char *frame_data;
    int     frame_length = 0;
    switch(send_type){
        case EAPOL_START:
            state = STARTED;
            frame_data= eapol_start;
            frame_length = 64;
            fprintf(stdout, ">>Protocol: SEND EAPOL-Start\n");
            break;
        case EAPOL_LOGOFF:
            state = READY;
            frame_data = eapol_logoff;
            frame_length = 64;
            fprintf(stdout, ">>Protocol: SEND EAPOL-Logoff\n");
            break;
        case EAP_RESPONSE_IDENTITY:
            frame_data = eap_response_ident;
            frame_length = 54 + username_length;
            fprintf(stdout, ">>Protocol: SEND EAP-Response/Identity\n");
            break;
        case EAP_RESPONSE_MD5_CHALLENGE:
            frame_data = eap_response_md5ch;
            frame_length = 40 + username_length + 14;
            fprintf(stdout, ">>Protocol: SEND EAP-Response/Md5-Challenge\n");
            break;
        case EAP_RESPONSE_IDENTITY_KEEP_ALIVE:
            frame_data = eapol_keepalive;
            frame_length = 64;
            fprintf(stdout, ">>Protocol: SEND EAPOL Keep Alive\n");
            break;
        default:
            fprintf(stderr,"&&IMPORTANT: Wrong Send Request Type.%02x\n", send_type);
            return;
    }
    if (debug_on){
        printf ("@@DEBUG: Sent Frame Data:\n");
        print_hex (frame_data, frame_length);
    }
    if (pcap_sendpacket(handle, frame_data, frame_length) != 0)
    {
        fprintf(stderr,"&&IMPORTANT: Error Sending the packet: %s\n", pcap_geterr(handle));
        return;
    }
}

/* Callback function for pcap.  */
void
get_packet(u_char *args, const struct pcap_pkthdr *header,
           const u_char *packet)
{
	/* declare pointers to packet headers */
	const struct sniff_ethernet *ethernet;  /* The ethernet header [1] */
    const struct sniff_eap_header *eap_header;
    
    ethernet = (struct sniff_ethernet*)(packet);
    eap_header = (struct sniff_eap_header *)(packet + SIZE_ETHERNET);
    
    if (debug_on){
        printf ("@@DEBUG: Packet Caputre Data:\n");
        print_hex (packet, 64);
    }
    
    enum EAPType p_type = get_eap_type(eap_header);
    action_by_eap_type(p_type, eap_header);
    
    return;
}

void
init_frames()
{
    int data_index;
    
    /*****  EAPOL Header  *******/
    u_char eapol_header[SIZE_ETHERNET];
    data_index = 0;
    u_short eapol_t = htons (0x888e);
    memcpy (eapol_header + data_index, muticast_mac, 6); /* dst addr. muticast */
    data_index += 6;
    memcpy (eapol_header + data_index, local_mac, 6);    /* src addr. local mac */
    data_index += 6;
    memcpy (eapol_header + data_index, &eapol_t, 2);    /*  frame type, 0x888e*/
    
    /**** EAPol START ****/
    u_char start_data[] = {0x01, 0x01, 0x00, 0x00};
    memset (eapol_start, 0xcc, 64);
    memcpy (eapol_start, eapol_header, 14);
    memcpy (eapol_start + 14, start_data, 4);
    memcpy (eapol_start + 14 + 4, talier_eapol_start, 6);
    
    //    print_hex(eapol_start, sizeof(eapol_start));
    /****EAPol LOGOFF ****/
    u_char logoff_data[4] = {0x01, 0x02, 0x00, 0x00};
    memset (eapol_logoff, 0xcc, 64);
    memcpy (eapol_logoff, eapol_header, 14);
    memcpy (eapol_logoff + 14, logoff_data, 4);
    memcpy (eapol_logoff + 14 + 4, talier_eapol_start, 4);
    
    //    print_hex(eapol_logoff, sizeof(eapol_logoff));
    
    /****EAPol Keep alive ****/
    u_char keep_data[4] = {0x01, 0xfc, 0x00, 0x0c};
    memset (eapol_keepalive, 0xcc, 64);
    memcpy (eapol_keepalive, eapol_header, 14);
    memcpy (eapol_keepalive + 14, keep_data, 4);
    memset (eapol_keepalive + 18, 0, 8);
    memcpy (eapol_keepalive + 26, &local_ip, 4);
    
    //    print_hex(eapol_keepalive, sizeof(eapol_keepalive));
    
    /* EAP RESPONSE IDENTITY */
    u_char eap_resp_iden_head[9] = {0x01, 0x00,
        0x00, 5 + username_length,  /* eapol_length */
        0x02, 0x00,
        0x00, 5 + username_length,       /* eap_length */
        0x01};
    
    //    eap_response_ident = malloc (54 + username_length);
    memset(eap_response_ident, 0xcc, 54 + username_length);
    
    data_index = 0;
    memcpy (eap_response_ident + data_index, eapol_header, 14);
    data_index += 14;
    memcpy (eap_response_ident + data_index, eap_resp_iden_head, 9);
    data_index += 9;
    memcpy (eap_response_ident + data_index, username, username_length);
    
    //    print_hex(eap_response_ident, 54 + username_length);
    /** EAP RESPONSE MD5 Challenge **/
    u_char eap_resp_md5_head[10] = {0x01, 0x00,
        0x00, 6 + 16 + username_length, /* eapol-length */
        0x02,
        0x00, /* id to be set */
        0x00, 6 + 16 + username_length, /* eap-length */
        0x04, 0x10};
    //    eap_response_md5ch = malloc (14 + 4 + 6 + 16 + username_length + 14);
    //    memset(eap_response_md5ch, 0xcc, 14 + 4 + 6 + 16 + username_length + 14);
    
    data_index = 0;
    memcpy (eap_response_md5ch + data_index, eapol_header, 14);
    data_index += 14;
    memcpy (eap_response_md5ch + data_index, eap_resp_md5_head, 10);
    data_index += 26;// 剩余16位在收到REQ/MD5报文后由fill_password_md5填充
    memcpy (eap_response_md5ch + data_index, username, username_length);
    data_index += username_length;
    memcpy (eap_response_md5ch + data_index, &local_ip, 4);
    data_index += 4;
    memcpy (eap_response_md5ch + data_index, talier_eap_md5_resp, 9);
    
    //    print_hex(eap_response_md5ch, 14 + 4 + 6 + 16 + username_length + 14);
    
}

void
fill_password_md5(u_char *attach_key, u_int id)
{
    char *psw_key = malloc(1 + password_length + 16);
    char *md5;
    psw_key[0] = id;
    memcpy (psw_key + 1, password, password_length);
    memcpy (psw_key + 1 + password_length, attach_key, 16);
    
    if (debug_on){
        printf("@@DEBUG: MD5-Attach-KEY:\n");
        print_hex ((u_char*)psw_key, 1 + password_length + 16);
    }
    
    md5 = get_md5_digest(psw_key, 1 + password_length + 16);
    
    memset (eap_response_md5ch + 14 + 5, id, 1);
    memcpy (eap_response_md5ch + 14 + 10, md5, 16);
    
    free (psw_key);
}

void init_info()
{
    if(username == NULL || password == NULL){
        fprintf (stderr,"Error: NO Username or Password promoted.\n"
                 "Try zlevoclient --help for usage.\n");
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error :用户名或密码读取错误"];
//        exit(EXIT_FAILURE);
    }
    username_length = (int)strlen(username);
    password_length = (int)strlen(password);
    
}

/*
 * ===  FUNCTION  ======================================================================
 *         Name:  init_device
 *  Description:  初始化设备。主要是找到打开网卡、获取网卡MAC、IP，
 *  同时设置pcap的初始化工作句柄。
 * =====================================================================================
 */
void init_device()
{
    struct          bpf_program fp;			/* compiled filter program (expression) */
    char            filter_exp[51];         /* filter expression [3] */
    pcap_if_t       *alldevs,*alldevsp,*alldevsp2;
    pcap_addr_t     *addrs;
    
	/* Retrieve the device list */
	if(pcap_findalldevs(&alldevs, errbuf) == -1)
	{
		fprintf(stderr,"Error in pcap_findalldevs: %s\n", errbuf);
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: in pcap_findalldevs"];
        //		exit(1);
	}
    
    /* 使用第一块设备 */
    dev=NULL;
    alldevsp=alldevs;
    alldevsp2=alldevs;
    if ([PreferencesModel sharedInstance].Device.length>0) {
        while (alldevsp&&alldevsp->name) {
            if ([[NSString stringWithUTF8String:alldevsp->name] isEqualToString:[PreferencesModel sharedInstance].Device]) {
                dev=alldevsp->name;
                break;
            }
            alldevsp=alldevsp->next;
        }
    }
    if(dev == NULL) {
        while (alldevsp2) {
            if (alldevsp2->name) {
                dev = alldevsp2->name;
                [PreferencesModel sharedInstance].Device=[NSString stringWithUTF8String:dev];
                break;
            }
            alldevsp2=alldevsp2->next;
        }
    }
    strcpy (dev_if_name, dev);
    
	if (dev == NULL) {
		fprintf(stderr, "Couldn't find default device: %s\n",
                errbuf);
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: Couldn't find the device"];
//		exit(EXIT_FAILURE);
    }
	
	/* open capture device */
	handle = pcap_open_live(dev, SNAP_LEN, 1, 1000, errbuf);
    
	if (handle == NULL) {
		fprintf(stderr, "Couldn't open device %s: %s\n", dev, errbuf);
        [[PreferencesModel sharedInstance] pushErrorLog:[NSString stringWithFormat:@"Error: Couldn't open device %s",dev]];
//		exit(EXIT_FAILURE);
	}
    
	/* make sure we're capturing on an Ethernet device [2] */
	if (pcap_datalink(handle) != DLT_EN10MB) {
		fprintf(stderr, "%s is not an Ethernet\n", dev);
        [[PreferencesModel sharedInstance] pushErrorLog:[NSString stringWithFormat:@"Error:网卡%s无效",dev]];
        return;
//		exit(EXIT_FAILURE);
	}
    
    /* Get IP ADDR and MASK */
    for (addrs = alldevs->addresses; addrs; addrs=addrs->next) {
        if (addrs->addr->sa_family == AF_INET) {
            local_ip = ((struct sockaddr_in *)addrs->addr)->sin_addr.s_addr;
        }
    }
    

    if (bsd_get_mac (dev, local_mac) != 0) {
		fprintf(stderr, "FATIL: Fail getting BSD/MACOS Mac Address.\n");
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: 读取mac地址错误"];
//		exit(EXIT_FAILURE);
    }
    
    /* construct the filter string */
    sprintf(filter_exp, "ether dst %02x:%02x:%02x:%02x:%02x:%02x"
            " and ether proto 0x888e",
            local_mac[0], local_mac[1],
            local_mac[2], local_mac[3],
            local_mac[4], local_mac[5]);
    
	/* compile the filter expression */
	if (pcap_compile(handle, &fp, filter_exp, 0, 0) == -1) {
		fprintf(stderr, "Couldn't parse filter %s: %s\n",
                filter_exp, pcap_geterr(handle));
        [[PreferencesModel sharedInstance] pushErrorLog:[NSString stringWithFormat:@"Error: Couldn't parse filter %s: %s",filter_exp, pcap_geterr(handle)]];
//		exit(EXIT_FAILURE);
	}
    
	/* apply the compiled filter */
	if (pcap_setfilter(handle, &fp) == -1) {
		fprintf(stderr, "Couldn't install filter %s: %s\n",
                filter_exp, pcap_geterr(handle));
        [[PreferencesModel sharedInstance] pushErrorLog:[NSString stringWithFormat:@"Error: Couldn't install filter %s: %s",filter_exp, pcap_geterr(handle)]];
//		exit(EXIT_FAILURE);
	}
    pcap_freecode(&fp);
    pcap_freealldevs(alldevs);
}

static void
signal_interrupted (int signo)
{
    fprintf(stdout,"\n&&Info: USER Interrupted. \n");
    send_eap_packet(EAPOL_LOGOFF);
    if (handle) {
        pcap_breakloop (handle);
        pcap_close (handle);
        handle=NULL;
    }
//    exit (EXIT_FAILURE);
}
void keep_alive()
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [NSThread sleepForTimeInterval:KEEP_ALIVE_TIME];
        if (state == ONLINE) {
            send_eap_packet (EAP_RESPONSE_IDENTITY_KEEP_ALIVE);
            keep_alive();
        }
    });
}

void
flock_reg ()
{
    char buf[16];
    struct flock fl;
    fl.l_start = 0;
    fl.l_whence = SEEK_SET;
    fl.l_len = 0;
    fl.l_type = F_WRLCK;
    fl.l_pid = getpid();
    
    //阻塞式的加锁
    if (fcntl (lockfile, F_SETLKW, &fl) < 0){
        perror ("fcntl_reg");
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: Can't lock file"];
//        exit(EXIT_FAILURE);
    }
    
    //把pid写入锁文件
    assert (0 == ftruncate (lockfile, 0) );
    sprintf (buf, "%ld", (long)getpid());
    assert (-1 != write (lockfile, buf, strlen(buf) + 1));
}

int
program_running_check()
{
    struct flock fl;
    fl.l_start = 0;
    fl.l_whence = SEEK_SET;
    fl.l_len = 0;
    fl.l_type = F_WRLCK;
    
    //尝试获得文件锁
    if (fcntl (lockfile, F_GETLK, &fl) < 0){
        perror ("fcntl_get");
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: Can't get lock lock"];
//        exit(EXIT_FAILURE);
    }
    
    if (exit_flag) {
        if (fl.l_type != F_UNLCK) {
            if ( kill (fl.l_pid, SIGINT) == -1 )
                perror("kill");
            fprintf (stdout, "&&Info: Kill Signal Sent to PID %d.\n", fl.l_pid);
        }
        else
            fprintf (stderr, "&&Info: NO zLenovoClient Running.\n");
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: One Client Already Running"];
//        exit (EXIT_FAILURE);
    }
    
    
    //没有锁，则给文件加锁，否则返回锁着文件的进程pid
    if (fl.l_type == F_UNLCK) {
        flock_reg ();
        return 0;
    }
    
    return fl.l_pid;
}

-(BOOL)isRunningCheck
{
    //打开锁文件
    lockfile = open (LOCKFILE, O_RDWR | O_CREAT , LOCKMODE);
    if (lockfile < 0){
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: Lockfile error"];
        perror ("Lockfile");
        return YES;
    }
    int ins_pid;
    if ( (ins_pid = program_running_check ()) ) {
        fprintf(stderr,"@@ERROR: ZLevoClient Already "
                "Running with PID %d\n", ins_pid);
        [[PreferencesModel sharedInstance] pushErrorLog:@"Error: One Client Already Running"];
        return YES;
    }
    return NO;
}

- (void)initEnvironment
{
    username = (char *)[[PreferencesModel sharedInstance].UserName cStringUsingEncoding:NSUTF8StringEncoding];
    password = (char *)[[PreferencesModel sharedInstance].UserPwd cStringUsingEncoding:NSUTF8StringEncoding];
    dev=NULL;
    init_info();
    init_device();
    init_frames ();
//    signal (SIGINT, signal_interrupted);
//    signal (SIGTERM, signal_interrupted);
//    signal (SIGALRM, keep_alive);
//    alarm(KEEP_ALIVE_TIME);
}


- (void)connetNeedInit:(BOOL)init sucess:(void(^)(void))sucess andFail:(void(^)(void))fail
{
    ConnetSucessBlock=[sucess copy];
    ConnetFailBlock=[fail copy];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!handle) {
            [self initEnvironment];
        }
//        printf("######## Lenovo Client ver. %s #########\n", LENOVO_VER);
//        printf("Device:     %s\n", dev_if_name);
//        printf("MAC:        %02x:%02x:%02x:%02x:%02x:%02x\n",
//               local_mac[0],local_mac[1],local_mac[2],
//               local_mac[3],local_mac[4],local_mac[5]);
//        printf("IP:         %s\n", inet_ntoa(*(struct in_addr*)&local_ip));
//        printf("########################################\n");
//        send_eap_packet (EAPOL_LOGOFF);
        send_eap_packet (EAPOL_START);
        pcap_loop (handle, -1, get_packet, NULL);   /* main loop */
        NSLog(@">>>>>>>pcap_loop--");
//        pcap_close (handle);
//        handle=NULL;
        ConnetSucessBlock=nil;
        ConnetFailBlock=nil;
        dispatch_async(dispatch_get_main_queue(), ^{
           fail();
        });
    });
}

- (void)cancle
{
    NSLog(@">>>>>>>cancle");
    if (handle) {
        pcap_breakloop(handle);
        NSLog(@">>>>>>>pcap_breakloop");
    }
    state = READY;
}

- (void)cancleWithcloseHandle
{
    [self cancle];
    pcap_close (handle);
    handle=NULL;
}

-(void)checkOnline:(void(^)(BOOL online))onLine
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if ([self PingHost:(char *)[[[PreferencesModel sharedInstance] CheckOfflineHost] UTF8String]]||[self PingHost:CheckOfflineHost1]||[self PingHost:CheckOfflineHost2]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                onLine(YES);
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                onLine(NO);
            });
        }        
    });
}

- (BOOL)PingHost:(char *)ip
{
    if (!ip) {
        return NO;
    }
    char sh[100]="ping -c 1 -W 500 ";
    strcat(sh,ip);
    if (0==system(sh)||0==system(sh)||0==system(sh)) {
        return YES;
    }
    return NO;
}

void executeSystem(const char *cmd, char *result)
{
    char buf_ps[1024];
    char ps[1024]={0};
    FILE *ptr;
    strcpy(ps, cmd);
    if((ptr=popen(ps, "r"))!=NULL)
    {
        while(fgets(buf_ps, 1024, ptr)!=NULL)
        {
            strcat(result, buf_ps);
            if(strlen(result)>=1024)
                break;
        }
        pclose(ptr);
        ptr = NULL;
    }
    else
    {
        printf("error\n");
    }
}


int bsd_get_mac(const char ifname[], uint8_t eth_addr[])
{
    struct ifreq *ifrp;
    struct ifconf ifc;
    char buffer[720];
    int socketfd,error,len,space=0;
    ifc.ifc_len=sizeof(buffer);
    len=ifc.ifc_len;
    ifc.ifc_buf=buffer;
    
    socketfd=socket(AF_INET,SOCK_DGRAM,0);
    
    if((error=ioctl(socketfd,SIOCGIFCONF,&ifc))<0)
    {
        perror("ioctl faild");
//        exit(1);
        return 1;
    }
    if(ifc.ifc_len<=len)
    {
        ifrp=ifc.ifc_req;
        do
        {
            struct sockaddr *sa=&ifrp->ifr_addr;
            
            if(((struct sockaddr_dl *)sa)->sdl_type==IFT_ETHER) {
                if (strcmp(ifname, ifrp->ifr_name) == 0){
                    memcpy (eth_addr, LLADDR((struct sockaddr_dl *)&ifrp->ifr_addr), 6);
                    return 0;
                }
            }
            ifrp=(struct ifreq*)(sa->sa_len+(caddr_t)&ifrp->ifr_addr);
            space+=(int)sa->sa_len+sizeof(ifrp->ifr_name);
        }
        while(space<ifc.ifc_len);
    }
    return 1;
}



- (NSArray *)readDeviceList
{
    pcap_if_t       *alldevs;
	/* Retrieve the device list */
	if(pcap_findalldevs(&alldevs, NULL) == -1)
	{
        return  nil;
	}
    NSMutableArray *arr=[[NSMutableArray alloc] initWithCapacity:8];
    while (alldevs&&alldevs->name) {
        [arr addObject:[NSString stringWithUTF8String:alldevs->name]];
        alldevs=alldevs->next;
    }
    return  (NSArray*)arr;
}

- (NSString *)readIpString
{
    return [self getIpString:[self selectedDev]];
}

- (NSString *)selectedDevName
{
    pcap_if_t *dev=[self selectedDev];
    if (dev&&dev->name) {
        return [NSString stringWithUTF8String:dev->name];
    }else{
        return nil;
    }
}

static pcap_if_t *alldevices;

- (pcap_if_t *)selectedDev
{
	/* Retrieve the device list */
	if(pcap_findalldevs(&alldevices, NULL) != -1)
	{
//        alldevices=NULL;
        pcap_if_t *palldevices=alldevices;
        if ([PreferencesModel sharedInstance].Device.length>0) {
            while (alldevices&&alldevices->name) {
                if ([[NSString stringWithUTF8String:alldevices->name] isEqualToString:[PreferencesModel sharedInstance].Device]) {
                    return alldevices;
                }
                alldevices=alldevices->next;
            }
        }
        if (palldevices&&palldevices->name) {
            [PreferencesModel sharedInstance].Device=[NSString stringWithUTF8String:palldevices->name];
            return palldevices;
        }else{
            [PreferencesModel sharedInstance].Device=@"";
            return NULL;
        }
    }
    return NULL;
}

- (NSString *)getIpString:(pcap_if_t *)alldevs
{
    if (alldevs&&alldevs->addresses) {
        pcap_addr_t     *addrs;
        /* Get IP ADDR and MASK */
        for (addrs = alldevs->addresses; addrs; addrs=addrs->next) {
            if (addrs->addr->sa_family == AF_INET) {
                u_int _ip = ((struct sockaddr_in *)addrs->addr)->sin_addr.s_addr;
                return [NSString stringWithUTF8String:inet_ntoa(*(struct in_addr*)&_ip)];
            }
        }
    }
    return @"0.0.0.0";
}

- (NSString *)readMacAddress
{
    u_char   mac_addr[ETHER_ADDR_LEN]; /* MAC地址 */
    pcap_if_t *_dev=[self selectedDev];
    if (_dev&&_dev->name) {
        if (bsd_get_mac (_dev->name, mac_addr) == 0) {
            /* construct the filter string */
            return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",mac_addr[0],mac_addr[1],mac_addr[2], mac_addr[3],mac_addr[4], mac_addr[5]];
        }
    }
    return @"";
}

- (NSString *)getGateWay
{
    char result[1024];
    executeSystem( "route -n get default|egrep gateway:|sed 's/.*gateway/gateway/'", result);
    printf("%s", result );
    char *p=&result[0];
    while ((char)p[0]!='g'&&(char)p[1]!='a'&&(char)p[2]!='t') {
        p++;
    }
    
    NSString *res=[NSString stringWithFormat:@"%s",p];
    NSRange range=[res rangeOfString:@"gateway:"];
    if (range.location==0) {
        NSString *gateway=[res substringFromIndex:range.location+range.length];
        return [gateway stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return @"";
}

-(void)getKbps:(int)sec speed:(void(^)(float upSpeed,float downSpeed))update
{
    dispatch_async(dispatch_get_main_queue(), ^{
        char *dev=[self selectedDev]->name;
        char *dev2=dev;
        struct follow f1;
        f1.inBytes=0;
        f1.outBytes=0;
        [self checkNetworkflow:dev f:&f1];
        [self performBlockInBackground:^{
            struct follow f2;
            f2.inBytes=0;
            f2.outBytes=0;
            [self checkNetworkflow:dev2 f:&f2];
            uint32_t up=f2.outBytes-f1.outBytes;
            uint32_t down=f2.inBytes-f1.inBytes;
            uint32_t usec=f2.time.tv_usec-f1.time.tv_usec;
            float sup=up*1.0/usec;
            float sdown=down*1.0/usec;
            update(sup,sdown);
        } afterDelay:1];
    });
}

-(void)checkNetworkflow:(char *)dev f:(struct follow *)_fcount
{
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1)
    {
        return;
    }
    struct follow *fcount=_fcount;
    fcount->inBytes=0;
    fcount->outBytes=0;
    gettimeofday(&(fcount->time), NULL);
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
    {
        if (AF_LINK != ifa->ifa_addr->sa_family)continue;
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))continue;
        if (ifa->ifa_data == 0)continue;
        if (strcmp(ifa->ifa_name,dev)) {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            fcount->inBytes += if_data->ifi_ibytes;
            fcount->outBytes += if_data->ifi_obytes;
        }
    }
    freeifaddrs(ifa_list);
}

@end
