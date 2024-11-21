%{
//------------VALORES INICIALES------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <ctype.h>

#define MAX_VAR_NAME_LENGTH 16
#define MAX_STRING_LENGTH 100

char abecedario[37] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 
'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' '};

char* enMorse[37] = {".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", 
"-.--", "--..", "-----", ".----", "..---", "...--", "....-", ".....", "-....", "--...", "---..", "----.", "/"};

int fd;
int duration;
char buffer[10];
int unidadDeTiempo = 300; //en MS
int retardoRepeticion = 5000; //en MS
struct termios options;

//------------DECLARACION DE FUNCIONES------------

int yylex(void);
void yyerror(const char *s);
void create_variable_texto(char *name, char *value);
void create_variable_entero(char *name, int value);
void validate_variable_name(char *name);
void verify_existance(char *name);
void verify_existance_texto(char *name);
void verify_existance_entero(char *name);
void print_variable(char *name);
void print_text(char *text);
char* get_variable_texto(char *name);
int get_variable_entero(char *name);
void modify_variable_texto(char *name, char *value);
void modify_variable_entero(char *name, int value);

void reproducirTexto(char* texto, int veces);
void reproducirVariable(char* name, int veces);
void cambiarUnidadDeTiempo(int tiempo);
void cambiarRetardoRepeticion(int tiempo);
void delay(int tiempo); //en MS

char* todoAMinuscula(char* texto);
int buscarLetraAbecedario(char letra);
void enviarPulsos(int i);
void recorrerMensaje(char* texto);

void abrirPuertoSerial(char* portName);
void cerrarPuertoSerial();

void reproducirTextoConIdentificador(char* texto, char* name);
void reproducirVariableConIdentificador(char* name, char* nombre);

//------------CREACION DE LISTAS DE TIPOS DE DATOS------------

typedef struct VariableTexto
{
    char *name;  // Nombre de la variable
    char *value; // Valor de la variable (puede ser una cadena)
    struct VariableTexto *next;  // Puntero a la siguiente variable
} VariableTexto;

VariableTexto *variablesTexto = NULL;  // Lista enlazada de variables de texto

typedef struct VariableEntero
{
    char *name;  // Nombre de la variable
    int value; // Valor de la variable (puede ser una cadena)
    struct VariableEntero *next;  // Puntero a la siguiente variable
} VariableEntero;

VariableEntero *variablesEntero = NULL;  // Lista enlazada de variables de texto
%}

%union {
    char *sval;
    int ival;
}

%token ENTERO TEXTO PRINT TIME_UNIT PLAY WAIT ENDL REPEAT OPEN_PORT CLOSE_PORT
%token <sval> IDENTIFIER STRING
%token <ival> NUMBER
%token INIT_BRACKET CLOSE_BRACKET EQUALS COMMA SEMICOLON

%%
program:
    statements  // El programa consiste en una secuencia de declaraciones
    ;

statements:
    statements statement
    | /* empty */  // O ninguna declaración
    ;

statement:
    TEXTO IDENTIFIER SEMICOLON // Declarar variable de tipo texto con valor vacío
    { 
        validate_variable_name($2);
        create_variable_texto($2, ""); 
    }
    | ENTERO IDENTIFIER SEMICOLON // Declarar variable de tipo entero con valor 0
    { 
        validate_variable_name($2);
        create_variable_entero($2, 0); 
    }
    | TEXTO IDENTIFIER EQUALS STRING SEMICOLON // Declarar variable de tipo texto con valor definido
    { 
        validate_variable_name($2);
        create_variable_texto($2, $4); 
    }
    | ENTERO IDENTIFIER EQUALS NUMBER SEMICOLON // Declarar variable de tipo entero con valor definido
    { 
        validate_variable_name($2);
        create_variable_entero($2, $4); 
    }
    | IDENTIFIER EQUALS STRING SEMICOLON // Modificar cadena a variable
    { 
        verify_existance($1);
        modify_variable_texto($1, $3);
    }
    | IDENTIFIER EQUALS NUMBER SEMICOLON // Modificar valor a variable
    { 
        verify_existance($1);
        modify_variable_entero($1, $3);
    }
    | PRINT INIT_BRACKET IDENTIFIER CLOSE_BRACKET SEMICOLON // Imprimir variable
    {
        verify_existance($3);
        print_variable($3); 
    }
    | PRINT INIT_BRACKET STRING CLOSE_BRACKET SEMICOLON // Imprimir texto
    {
        print_text($3);
    }
    | PLAY INIT_BRACKET STRING COMMA NUMBER CLOSE_BRACKET SEMICOLON // Reproducir texto
    {
        reproducirTexto($3, $5);
    }
    | PLAY INIT_BRACKET IDENTIFIER COMMA NUMBER CLOSE_BRACKET SEMICOLON // Reproducir variable
    {
        verify_existance_texto($3);
        reproducirVariable($3, $5);
    }
    | PLAY INIT_BRACKET STRING COMMA IDENTIFIER CLOSE_BRACKET SEMICOLON // Reproducir texto con identificador
    {
        verify_existance_entero($5);
        reproducirTextoConIdentificador($3, $5);
    }
    | PLAY INIT_BRACKET IDENTIFIER COMMA IDENTIFIER CLOSE_BRACKET SEMICOLON // Reproducir variable con identificador
    {
        verify_existance_texto($3);
        verify_existance_entero($5);
        reproducirVariableConIdentificador($3, $5);
    }
    | TIME_UNIT EQUALS NUMBER SEMICOLON // Cambiar valor de la unidad de tiempo
    {
        cambiarUnidadDeTiempo($3);
    }
    | REPEAT EQUALS NUMBER SEMICOLON // Cambiar valor de la unidad de tiempo
    {
        cambiarRetardoRepeticion($3);
    }
    | WAIT INIT_BRACKET NUMBER CLOSE_BRACKET SEMICOLON // Cambiar valor de la unidad de tiempo
    {
        delay($3);
    }
    | ENDL SEMICOLON // Hago un salto de linea
    {
        printf("\n");
    }
    | OPEN_PORT INIT_BRACKET STRING CLOSE_BRACKET SEMICOLON // Hago un salto de linea
    {
        abrirPuertoSerial($3);
    }
    | CLOSE_PORT SEMICOLON // Hago un salto de linea
    {
        cerrarPuertoSerial();
    }
    ;
%%

//------------DEFINICION DE FUNCIONES------------

// Función para manejar errores
void yyerror(const char *s) 
{
    fprintf(stderr, "Error: %s\n", s);
}

//Funcion para validar el nombre de las variables
void validate_variable_name(char *name) 
{
    VariableTexto *varTXT = variablesTexto;
    VariableEntero *varINT = variablesEntero;

    while (varTXT != NULL)
    {
        if (strcmp(varTXT->name, name) == 0)
        {
            fprintf(stderr, "Error: El nombre de la variable '%s' no se encuentra disponible\n", name);
            exit(EXIT_FAILURE);
        }
        varTXT = varTXT->next;
    }

    while (varINT != NULL)
    {
        if (strcmp(varINT->name, name) == 0)
        {
            fprintf(stderr, "Error: El nombre de la variable '%s' no se encuentra disponible\n", name);
            exit(EXIT_FAILURE);
        }
        varINT = varINT->next;
    }

    if (strlen(name) > MAX_VAR_NAME_LENGTH) 
    {
        fprintf(stderr, "Error: El nombre de la variable '%s' excede el límite de %d caracteres\n", name, MAX_VAR_NAME_LENGTH);
        exit(EXIT_FAILURE);
    }
}

// Funcion para verificar la existencia de una variable
void verify_existance(char *name)
{
    int existe = 0;

    VariableTexto *varTXT = variablesTexto;
    VariableEntero *varINT = variablesEntero;

    while (varTXT != NULL)
    {
        if (strcmp(varTXT->name, name) == 0)
        {
            existe = 1;
        }
        varTXT = varTXT->next;
    }

    while (varINT != NULL)
    {
        if (strcmp(varINT->name, name) == 0)
        {
            existe = 1;
        }
        varINT = varINT->next;
    }
    
    if(!existe)
    {
        fprintf(stderr, "Error: La variable '%s' no existe\n", name);
        exit(EXIT_FAILURE);
    }
}

// Funcion para verificar la existencia de una variable del tipo texto
void verify_existance_texto(char *name)
{
    int existe = 0;

    VariableTexto *varTXT = variablesTexto;

    while (varTXT != NULL)
    {
        if (strcmp(varTXT->name, name) == 0)
        {
            existe = 1;
        }
        varTXT = varTXT->next;
    }

    if(!existe)
    {
        fprintf(stderr, "Error: La variable '%s' no es de tipo texto\n", name);
        exit(EXIT_FAILURE);
    }
}

// Funcion para verificar la existencia de una variable del tipo entero
void verify_existance_entero(char *name)
{
    int existe = 0;

    VariableEntero *varINT = variablesEntero;

    while (varINT != NULL)
    {
        if (strcmp(varINT->name, name) == 0)
        {
            existe = 1;
        }
        varINT = varINT->next;
    }

    if(!existe)
    {
        fprintf(stderr, "Error: La variable '%s' no es de tipo entero\n", name);
        exit(EXIT_FAILURE);
    }
}

// Función para asignar valor a una variable de texto
void create_variable_texto(char *name, char *value)
{
    VariableTexto *var = (VariableTexto *) malloc(sizeof(VariableTexto));
    var->name = strdup(name);
    var->value = strdup(value);
    var->next = variablesTexto;
    variablesTexto = var;
}

// Funcion para modificar el valor de una variable de texto
void modify_variable_texto(char *name, char *value)
{
    verify_existance_texto(name);

    VariableTexto *var = variablesTexto;

    while (var != NULL)
    {
        if (strcmp(var->name, name) == 0)
        {
            free(var->value); // Liberar memoria del valor existente
            var->value = strdup(value);
            return;
        }
        var = var->next;
    }
}

// Función para asignar valor a una variable entera
void create_variable_entero(char *name, int value)
{
    VariableEntero *var = (VariableEntero *) malloc(sizeof(VariableEntero));
    var->name = strdup(name);
    var->value = value;
    var->next = variablesEntero;
    variablesEntero = var;
}

// Funcion para modificar el valor de una variable entera
void modify_variable_entero(char *name, int value)
{
    verify_existance_entero(name);

    VariableEntero *var = variablesEntero;
    
    while (var != NULL)
    {
        if (strcmp(var->name, name) == 0)
        {
            var->value = value;
            return;
        }
        var = var->next;
    }
}

// Función para obtener el valor de una variable
char* get_variable_texto(char *name)
{
    VariableTexto *var = variablesTexto;
    while (var != NULL)
    {
        if (strcmp(var->name, name) == 0)
        {
            return var->value;
        }
        var = var->next;
    }
    return "";
}

int get_variable_entero(char *name)
{
    VariableEntero *var = variablesEntero;
    
    while (var != NULL)
    {
        if (strcmp(var->name, name) == 0)
        {
            return var->value;
        }
        var = var->next;
    }

    printf("La variable \"%s\" no existe", name);
    return 0;
}

// Función para imprimir el valor de una variable
void print_variable(char *name)
{
    char *valueTexto = get_variable_texto(name);
    if(strcmp(valueTexto, "") == 0)
    {
        int valueEntero = get_variable_entero(name);
        printf("%d", valueEntero);
    }
    else
    {
        printf("%s", valueTexto);
    }
    fflush(stdout); // Asegurarse de que el buffer de salida se vacíe
}

// Función para imprimir el valor de una variable
void print_text(char *text)
{
    printf("%s", text);
    fflush(stdout); // Asegurarse de que el buffer de salida se vacíe
}

void reproducirTexto(char* texto, int veces)
{
    char* textoEnMinuscula = todoAMinuscula(texto);

    for(int i = 0; i < veces; i++)
    {
        recorrerMensaje(textoEnMinuscula);

        usleep(retardoRepeticion * 1000);
    }

    free(textoEnMinuscula);
}

void reproducirTextoConIdentificador(char* texto, char* name)
{
    int veces = get_variable_entero(name);
    
    char* textoEnMinuscula = todoAMinuscula(texto);

    for(int i = 0; i < veces; i++)
    {
        recorrerMensaje(textoEnMinuscula);

        usleep(retardoRepeticion * 1000);
    }

    free(textoEnMinuscula);
}

void reproducirVariable(char* name, int veces)
{
    char *texto = get_variable_texto(name);

    char* textoEnMinuscula = todoAMinuscula(texto);

    for(int i = 0; i < veces; i++)
    {
        recorrerMensaje(textoEnMinuscula);

        usleep(retardoRepeticion * 1000);
    }

    free(textoEnMinuscula);
}

void reproducirVariableConIdentificador(char* name, char* nombre)
{
    char *texto = get_variable_texto(name);

    int veces = get_variable_entero(nombre);

    char* textoEnMinuscula = todoAMinuscula(texto);

    for(int i = 0; i < veces; i++)
    {
        recorrerMensaje(textoEnMinuscula);

        usleep(retardoRepeticion * 1000);
    }

    free(textoEnMinuscula);
}

void recorrerMensaje(char* texto)
{
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

void cambiarUnidadDeTiempo(int tiempo)
{
    unidadDeTiempo = tiempo;
}

void cambiarRetardoRepeticion(int tiempo)
{
    retardoRepeticion = tiempo;
}

void delay(int tiempo)
{
    usleep(tiempo * 1000);
}

char* todoAMinuscula(char* texto)
{
    //Creo una variable de tipo entero para almacenar el desplazamiento
    int desplazamiento = 0;

    char* textoEnMinuscula = strdup(texto);
    
    //Mientras el caracter apuntado por el puntero sea distinto de \0
    while(*textoEnMinuscula != '\0')
    {
        *textoEnMinuscula = tolower((char)*textoEnMinuscula);
        textoEnMinuscula++;
        desplazamiento++;
    }

    //Regreso el puntero a la posicion inicial
    textoEnMinuscula -= desplazamiento;

    return textoEnMinuscula;
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

void abrirPuertoSerial(char* portName)
{
    //Abrir el puerto serie
    fd = open(portName, O_RDWR | O_NOCTTY);

    if (fd == -1) {
        perror("Error al abrir el puerto serie");
        return;
    }

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
}

void cerrarPuertoSerial()
{
    close(fd);
}

int main(void)
{
    return yyparse();  // Llamar al analizador sintáctico
}