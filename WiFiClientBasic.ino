#include <WiFi.h>
#include <WiFiMulti.h>

WiFiMulti WiFiMulti;

WiFiClient terminal;

// Telnet protocol codes (https://github.com/martydill/telnet/blob/master/TelnetProtocol.h)
const byte ECHO = 1;
const byte IAC = 255;
const byte DONT = 254;
const byte DO = 253;
const byte WONT = 252;
const byte WILL = 251;
const byte SB = 250; // Suboption Begin
const byte SE = 240; // Suboption End
const byte TERMINALTYPE = 24;
const byte WINDOWSIZE = 31;
const byte TERMINALSPEED = 32;
const byte ENVIRONMENTOPTION = 39;
const byte XDISPLAYLOCATION = 35;
const byte ENVIRONMENTOPTION2 = 36;

const byte user[3] = {0x70, 0x69, 0x0A}; // pi
const byte pass[] = ****** YOUR PASSWORD GOES HERE ******
//const byte VT100[11] = {0xFF, 0xFA, 0x18, 0x00, 0x56, 0x54, 0x31, 0x30, 0x30, 0xFF, 0xF0}; // "Here's my Terminal Type"
const byte date[15] = {0x64, 0x61, 0x74, 0x65, 0x20, 0x2B, 0x25, 0x25, 0x25, 0x48, 0x25, 0x4D, 0x25, 0x53, 0x0A}; // date +%t%H%M%S

const int resetPin = 25;
const int clockPin = 26;
const int dataPin = 27;

void setup()
{
    // terminal.setNoDelay(true);
    // terminal.setTimeout(100);

    pinMode(resetPin, OUTPUT);
    pinMode(clockPin, OUTPUT);
    pinMode(dataPin, OUTPUT);

    Serial.begin(115200);
    delay(10);

    WiFiMulti.addAP(****** YOUR WIFI CREDENTIALS GO HERE ******);

    Serial.println();
    Serial.print("Waiting for WiFi...");

    while(WiFiMulti.run() != WL_CONNECTED)
    {
        Serial.print(".");
        delay(500);
    }

    Serial.println();
    Serial.println("WiFi connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    delay(500);

    const uint16_t port = 23;
    const char * host = ****** YOUR HOST IP ADDRESS GOES HERE ******

    Serial.print("Connecting to ");
    Serial.println(host);

    if (!terminal.connect(host, port))
        Serial.println("Connection failed.");
}

void loop()
{
    byte current;
    byte digits[6];
    byte counterA = 0;
    byte counterB = 1;
    bool sent1 = false;
    bool sent2 = false;

    while(1)
    {
        if(terminal.available() > 0)
        {
            current = terminal.read();

            if(current == 0x24)
            {
                terminal.write(date, 15);
            }
            else if(current == 0x25)
            {
                terminal.readBytes(digits, 6);

                if(digits[0] > 0x2F && digits[0] < 0x33)
                {
                    REG_WRITE(GPIO_OUT_W1TS_REG, ((1<<resetPin) | REG_READ(GPIO_OUT_W1TS_REG)));
                    REG_WRITE(GPIO_OUT_W1TS_REG, ((1<<clockPin) | REG_READ(GPIO_OUT_W1TS_REG)));
                    REG_WRITE(GPIO_OUT_W1TC_REG, ((3<<resetPin) | REG_READ(GPIO_OUT_W1TC_REG))); // reset + clock

                    for(byte b = 0; b < 3; b++)
                    {
                        digits[counterA] -= 48; // convert from ASCII
                        digits[counterB] -= 48;
                        digits[counterB] |= (digits[counterA] << 4);
                        shiftOutFast(digits[counterB]);
                        counterA += 2;
                        counterB += 2;
                    }

                    counterA = 0;
                    counterB = 1;
                }
            }
            else if(current == 0x3A && sent1 == false && sent2 == false)
            {
                sent1 = true;
                terminal.write(user, 3);
            }
            else if(current == 0x3A && sent1 == true && sent2 == false)
            {
                sent2 = true;
                terminal.write(pass, 9);
            }
            else if(current == IAC)
                handleCommand();
         // else
             // Serial.write(current); // stuff to be displayed
        }
    }
}

// Deal with a single command (https://github.com/martydill/telnet/blob/master/TelnetSession.cpp)
void handleCommand()
{
    byte buf[2];

    terminal.readBytes(buf, 2);

    if(buf[0] == DO || buf[0] == DONT)
        respondToRequest(buf[0], buf[1]);
    else if(buf[0] == WILL || buf[0] == WONT)
        respondToStatement(buf[0], buf[1]);
//  else if(buf[0] == SB && buf[1] == TERMINALTYPE)
//      terminal.write(VT100, 11);

    return;
}

// Respond to a DO/DONT request
void respondToRequest(byte command, byte option)
{
    terminal.write(IAC);

    if(command == DONT || option == TERMINALTYPE || option == WINDOWSIZE || option == TERMINALSPEED || option == ENVIRONMENTOPTION || option == XDISPLAYLOCATION || option == ENVIRONMENTOPTION2)
        terminal.write(WONT);
    else
        terminal.write(WILL);

    terminal.write(option);

/*  Serial.print(IAC,HEX);
    Serial.print(" ");

    if(command == DONT || option == TERMINALTYPE || option == WINDOWSIZE || option == TERMINALSPEED || option == ENVIRONMENTOPTION || option == XDISPLAYLOCATION || option == ENVIRONMENTOPTION2)
        Serial.print(WONT,HEX);
    else
        Serial.print(WILL,HEX);

    Serial.print(" ");
    Serial.println(option,HEX); */

    return;
}

// Respond to a WILL/WONT statement
void respondToStatement(byte command, byte option)
{
    terminal.write(IAC);

    if(command == WONT || option == ECHO)
        terminal.write(DONT);
    else
        terminal.write(DO);

    terminal.write(option);

/*  Serial.print(IAC,HEX);
    Serial.print(" ");

    if(command == WONT || option == ECHO)
        Serial.print(DONT,HEX);
    else
        Serial.print(DO,HEX);

    Serial.print(" ");
    Serial.println(option,HEX); */

    return;
}

// http://nerdralph.blogspot.com/2015/04/a-4mbps-shiftout-for-esp8266arduino.html
void shiftOutFast(byte numbers)
{
    byte i = 8;

    do
    {
        REG_WRITE(GPIO_OUT_W1TC_REG, ((3<<clockPin) | REG_READ(GPIO_OUT_W1TC_REG))); // clock + data

        if(numbers & 0x80)
            REG_WRITE(GPIO_OUT_W1TS_REG, ((1<<dataPin) | REG_READ(GPIO_OUT_W1TS_REG)));

        REG_WRITE(GPIO_OUT_W1TS_REG, ((1<<clockPin) | REG_READ(GPIO_OUT_W1TS_REG)));

        numbers <<= 1;

    } while(--i);

    REG_WRITE(GPIO_OUT_W1TC_REG, ((1<<clockPin) | REG_READ(GPIO_OUT_W1TC_REG)));

    return;
}
