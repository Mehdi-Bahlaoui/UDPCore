#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>

// Your WiFi credentials
const char *ssid = "mehdi";
const char *password = "bahlaoui";

int LedPin = 8; // Pin for the LED

WiFiUDP udp;
const int localPort = 4210;
char incomingPacket[255];

// LED blink control variables
unsigned long ledOnTimestamp = 0;
const unsigned long ledDuration = 50;  // LED on time in milliseconds
bool ledIsOn = false;

void handleCommand(const char *cmd)
{   
    // Turn on LED and note time
    digitalWrite(LedPin, LOW);
    ledOnTimestamp = millis();
    ledIsOn = true;

    // if (strcmp(cmd, "F") == 0)
    // {
    //     Serial.println("Forward");
    // }
    // else if (strcmp(cmd, "B") == 0)
    // {
    //     Serial.println("Backward");
    // }
    // else if (strcmp(cmd, "L") == 0)
    // {
    //     Serial.println("Left");
    // }
    // else if (strcmp(cmd, "R") == 0)
    // {
    //     Serial.println("Right");
    // }
    // else if (strcmp(cmd, "S") == 0)
    // {
    //     Serial.println("Stop");
    // }
    // else
    // {
    //     Serial.print("Unknown command: ");
    //     Serial.println(cmd);
    // }
}

void setup()
{
    delay(1000); // Wait for a second to stabilize
    Serial.begin(115200);

    pinMode(LedPin, OUTPUT);
    digitalWrite(LedPin, HIGH); // Turn off LED initially

    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    udp.begin(localPort);
}

void loop()
{
    int packetSize = udp.parsePacket();
    if (packetSize)
    {
        int len = udp.read(incomingPacket, 255);
        if (len > 0)
        {
            incomingPacket[len] = 0;
            handleCommand(incomingPacket);
        }
    }

    // Check if LED should be turned off
    if (ledIsOn && (millis() - ledOnTimestamp >= ledDuration))
    {
        digitalWrite(LedPin, HIGH);  // Turn off LED
        ledIsOn = false;
    }
}
