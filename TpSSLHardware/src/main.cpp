#include <Arduino.h>

void clearInputBuffer() 
{
  while(Serial.available() > 0) 
  {
    Serial.read(); // Leer y descartar los datos
  }
}

void setup() 
{
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop()
{
  if(Serial.available() > 0)
  {
    //Leer el número del puerto serie
    int duration = Serial.parseInt();

    clearInputBuffer();

    //Con el numero leido enciendo el led y espero una determinada cantidad de tiempo hasta apagarlo
    digitalWrite(LED_BUILTIN, HIGH);
    delay(duration);
    digitalWrite(LED_BUILTIN, LOW);

    //Envio la confirmacion
    Serial.write('S');
  }
}