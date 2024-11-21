%{
#include "codigoBison.tab.h"
#include <string.h>
#include <stdlib.h>

#define MAX_VAR_NAME_LENGTH 16
%}

%option noyywrap

%%
"entero"         { return ENTERO; }
"texto"          { return TEXTO; }
"imprimir"       { return PRINT; }
"reproducir"     { return PLAY; }
"espera"         { return WAIT; }
"unidadDeTiempo" { return TIME_UNIT; }
"saltoDeLinea"   { return ENDL; }
"retardoRepeticion" { return REPEAT; }
"abrirPuerto"    { return OPEN_PORT; }
"cerrarPuerto"    { return CLOSE_PORT; }

\"([^\"\n]*)\"    { 
    yylval.sval = strdup(yytext + 1); // Eliminar las comillas
    yylval.sval[strlen(yylval.sval) - 1] = '\0'; // Eliminar la comilla final
    return STRING;
}

[a-zA-Z][a-zA-Z0-9]* {
    yylval.sval = strdup(yytext);
    return IDENTIFIER;
}

[0-9]+             { yylval.ival = atoi(yytext); return NUMBER; }
"("                { return INIT_BRACKET; }
")"                { return CLOSE_BRACKET; }
"="                { return EQUALS; }
","                { return COMMA; }
";"                { return SEMICOLON; }
[ \t\n]            { /* Ignorar espacios en blanco */ }
.                  { printf("Caracter inesperado: %s\n", yytext); }
%%