#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <readline/readline.h>

char abecedario[37] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 
'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' '};

char* enMorse[37] = {".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", 
"-.--", "--..", "-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----.", "/"};

int fd;
int duration;
int unidadDeTiempo = 250; //En MS
char buffer[10];

void todoAMinuscula(char* texto)
{
    //Creo una variable de tipo entero para almacenar el desplazamiento
    int desplazamiento = 0;
    
    //Mientras el caracter apuntado por el puntero sea distinto de \0
    while(*texto != '\0')
    {
        *texto = tolower((char)*texto);
        texto++;
        desplazamiento++;
    }

    //Regreso el puntero a la posicion inicial
    texto -= desplazamiento;
}

int buscarLetraAbecedario(char letra)
{
    int i = 0;
    while(abecedario[i] != letra)
    {
        i++;
    }

    return i;
}

void enviarPulsos(int i)
{
    int j = 0;
    while(*enMorse[i] != '\0')
    {
        //Si es un . envio un pulso de 1 unidad de tiempo
        if(*enMorse[i] == '.')
        {
            duration = unidadDeTiempo;

            //Convertir el número a cadena y enviarlo al Arduino
            snprintf(buffer, sizeof(buffer), "%d", duration);
            write(fd, buffer, strlen(buffer));
                    
            //Enviar un salto de línea para indicar el final del comando
            write(fd, "\n", 1);

            //Espero la respuesta del arduino
            char respuesta;
            read(fd, &respuesta, 1);
        }

        //Si es un - envio un pulso de 3 unidades de tiempo
        else if(*enMorse[i] == '-')
        {
            duration = 3 * unidadDeTiempo;

            //Convertir el número a cadena y enviarlo al Arduino
            snprintf(buffer, sizeof(buffer), "%d", duration);
            write(fd, buffer, strlen(buffer));
                    
            //Enviar un salto de línea para indicar el final del comando
            write(fd, "\n", 1);

            //Espero la respuesta del arduino
            char respuesta;
            read(fd, &respuesta, 1);
        }

        //Si es un / espero 7 unidades de tiempo
        else
        {
            usleep(7 * unidadDeTiempo * 1000);
        }

        //Espero una unidad de tiempo antes de enviar el siguiente . o -
        usleep(unidadDeTiempo * 1000);

        enMorse[i]++;
        j++;
    }

    //Vuelvo el puntero a su posicion inicial
    enMorse[i] -= j;
}

int main()
{
    struct termios options;
    char* texto;

    //Cambia esto según el nombre de tu puerto serie
    char portname[] = "/dev/ttyACM0";

    //Abrir el puerto serie
    fd = open(portname, O_RDWR | O_NOCTTY);

    //Configurar el puerto serie
    tcgetattr(fd, &options);
    cfsetispeed(&options, B9600);
    cfsetospeed(&options, B9600);
    options.c_cflag |= (CLOCAL | CREAD);
    options.c_iflag &= ~(IXON | IXOFF | IXANY); // Deshabilitar el control de flujo por software
    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // Modo no canónico
    options.c_oflag &= ~OPOST; // Sin procesamiento de salida
    options.c_cc[VMIN] = 1; // Leer al menos un carácter
    options.c_cc[VTIME] = 0; // Sin temporizador
    tcsetattr(fd, TCSANOW, &options);

    while(1)
    {
        //Leer el número desde la terminal
        printf("Ingrese el texto que desea enviar: ");
        texto = readline("");

        todoAMinuscula(texto);

        int desplazamiento = 0;

        //Recorro el texto
        while(*texto != '\0')
        {
            //Busco la letra en el vector abecedario
            int i = buscarLetraAbecedario(*texto);

            //Una vez encontrada la letra, la traduzco a morse y envio los pulsos al microcontrolador
            enviarPulsos(i);

            //Espero 3 unidades de tiempo antes de enviar otro caracter
            usleep(3 * unidadDeTiempo * 1000);

            //avanzo de caracter en el texto
            texto++;
            desplazamiento++;
        }
        texto -= desplazamiento;
    }

    // Cerrar el puerto serie
    close(fd);

    return 0;
}