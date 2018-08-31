//
//  main.m
//  fishhook
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "fishhook.h"

// 定义函数的指针变量，用户保存原来的函数指针（函数其实也是一个地址）
static int (*orig_close)(int);
static int (*orig_open)(const char *, int, ...);

// 自定义的close函数
int my_close(int fd) {
    printf("Calling real close(%d)\n", fd);
    return orig_close(fd);
}

// 自定义的open函数
int my_open(const char *path, int oflag, ...) {
    va_list ap = {0};
    mode_t mode = 0;
    
    if ((oflag & O_CREAT) != 0) {
        // mode only applies to O_CREAT
        va_start(ap, oflag);
        mode = va_arg(ap, int);
        va_end(ap);
        printf("Calling real open('%s', %d, %d)\n", path, oflag, mode);
        return orig_open(path, oflag, mode);
    } else {
        printf("Calling real open('%s', %d)\n", path, oflag);
        return orig_open(path, oflag, mode);
    }
}

int main(int argc, char * argv[])
{
    @autoreleasepool {
        
        // rebind_symbols((struct rebinding[2]){{"close", my_close, (void *)&orig_close}, {"open", my_open, (void *)&orig_open}}, 2);
        // 转换为：=====>
        
        struct rebinding binds[2];
        // orig_close是一个函数指针，(void *)&orig_close 是一个返回参数，所以用取地址，(void *)&orig_open也是类似的
        struct rebinding bind1 = {"close", my_close, (void *)&orig_close};
        binds[0] = bind1;
        binds[1] = (struct rebinding){"open", my_open, (void *)&orig_open};
        //重新绑定符号 参数 1 为符号相关信息 参数 2 为个数
        rebind_symbols(binds, 2);
        
        // Open our own binary and print out first 4 bytes (which is the same
        // for all Mach-O binaries on a given architecture)
        int fd = open(argv[0], O_RDONLY);
        uint32_t magic_number = 0;
        read(fd, &magic_number, 4);
        printf("Mach-O Magic Number: %x \n", magic_number);
        close(fd);
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
