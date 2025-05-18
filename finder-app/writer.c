#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    openlog("WriterDebug", LOG_PID | LOG_CONS, LOG_USER);
    if(argc == 3)
    {
        FILE *file = fopen(argv[1],"w" ); 
        if(file == NULL)
        {
            syslog(LOG_ERR,"File couldnt open %s, program fail", argv[1]);
            closelog();
            return 1;
        }
        fprintf(file, "%s", argv[2]);
        syslog(LOG_DEBUG,"Writing %s to %s", argv[2], argv[1]);
        fclose(file);
        closelog();
        return 0;
    }
    else
    {
        syslog(LOG_ERR,"ERROR: Invalid Number of Arguments. \r\n Total number of arguments should be 2.");
        closelog();
        return 1;
    }
}



// if [ $# = 2 ]
// then
	
// 	mkdir -p "$(dirname "$1")"
// 	echo "$2" > "$1"
// 	exit 0

		
// else
// 	echo "ERROR: Invalid Number of Arguments. \r\n Total number of arguments should be 2."
// 	exit 1

// fi

