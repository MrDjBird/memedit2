#import <Foundation/Foundation.h>

#ifdef RELEASE_BUILD
#define RLog(...) NSLog(__VA_ARGS__)
#define RLogv(format, args) NSLogv(format, args)
#else
#import <netinet/in.h>
#import <sys/socket.h>
#import <unistd.h>
#import <arpa/inet.h>

#ifndef REMOTE_LOG_IP
#error remote log server ip is not set
#endif
#define REMOTE_LOG_PORT 1337

static void RLogv(NSString *format, va_list args)
{
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];

    int sockfd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfd <= 0)
    {
        NSLog(@"remote log socket no open");
        return;
    }

    struct sockaddr_in dest;
    dest.sin_family = AF_INET;
    inet_pton(AF_INET, REMOTE_LOG_IP, &dest.sin_addr);
    dest.sin_port = htons(REMOTE_LOG_PORT);

    char *request = (char *)[str UTF8String];
    int bytes = sendto(sockfd, request, strlen(request), 0, (struct sockaddr *)&dest, sizeof dest);
    if (bytes < 0)
    {
        NSLog(@"remote log message no send");
        close(sockfd);
        return;
    }
    close(sockfd);
}

static void RLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    RLogv(format, args);
    va_end(args);
}

#endif
