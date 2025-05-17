#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    if (argc != 3) {
        syslog(LOG_ERR, "Error: Two arguments required.");
        syslog(LOG_ERR, "Usage: %s <writefile> <writestr>", argv[0]);
        closelog();
        return 1;
    }

    char *writefile = argv[1];
    char *writestr = argv[2];

    FILE *fp = fopen(writefile, "w");
    if (fp == NULL) {
        syslog(LOG_ERR, "Error: Could not open file %s for writing.", writefile);
        closelog();
        return 1;
    }

    if (fwrite(writestr, sizeof(char), strlen(writestr), fp) != strlen(writestr)) {
        syslog(LOG_ERR, "Error: Could not write to file %s.", writefile);
        fclose(fp);
        closelog();
        return 1;
    }

    fclose(fp);

    syslog(LOG_DEBUG, "Writing '%s' to '%s'", writestr, writefile);

    closelog();
    return 0;
}