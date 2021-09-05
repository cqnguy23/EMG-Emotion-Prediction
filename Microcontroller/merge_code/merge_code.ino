#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Declaration of BLE
BLEServer* pServer = NULL;

BLECharacteristic* pCharacteristicOne = NULL;

bool deviceConnected = false;
bool oldDeviceConnected = false;

// Declaration of ADC channels and their corresponding GPIO pins
const int ADC6_pin_1 = 34; // connect to left eyebrown muscle
const int ADC6_pin_2 = 35; // connect to left under-eye muscle
const int ADC6_pin_3 = 32; // connect to right cheek muscle

//Declaration of sampling variables
portMUX_TYPE DRAM_ATTR timerMux = portMUX_INITIALIZER_UNLOCKED;
hw_timer_t * adcTimer = NULL; // our timer
static TaskHandle_t adcTaskHandle = NULL;
int abufa, abufb, abufc;
int16_t test = 1;
int16_t countera = 0;
int16_t counterb = 0;
int16_t counterc = 0;
float seconds = 0;

#define SERVICE_UUID_ONE        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"



#define CHARACTERISTIC_UUID_ONE   "beb5483e-36e1-4688-b7f5-ea07361b26a8"

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t *param) {
      pServer->updateConnParams(param->connect.remote_bda, 0x01, 0x90, 0, 800);
      deviceConnected = true;
      //BLEDevice::startAdvertising();
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

void IRAM_ATTR send_data(int sensora, int sensorb, int sensorc) {
  if (deviceConnected) {
    /*Serial.print("Sensor 1 = ");
    Serial.println(sensora);

    Serial.print("Sensor 2 = ");
    Serial.println(sensorb);

    Serial.print("Sensor 3 = ");
    Serial.println(sensorc);
    */
    uint8_t first[4];
    uint8_t second[4];
    uint8_t third[4];
    
    int temp1 = sensora;
    int temp2 = sensorb;
    int temp3 = sensorc;
    int count1, count2, count3;
    if (temp1 < 256) {
      first[1] = 0;
      first[0] = uint8_t(temp1);
    }
    
    else {
        while(temp1 > 0) {
        first[count1] = uint8_t(temp1&0xFF);
        temp1 = temp1 >> 8; 
        count1++;
      }
    }

    if (temp2 < 256) {
      second[1] = 0;
      second[0] = uint8_t(temp2);
    }
    else {
      while(temp2 > 0) {
        second[count2] = uint8_t(temp2&0xFF);
        temp2 = temp2 >> 8; 
        count2++;
      }
    }
    if (temp3 < 256) {
      third[1] = 0;
      third[0] = uint8_t(temp3);
    }
    else 
    {
      while(temp3 > 0) {
        third[count3] = uint8_t(temp3&0xFF);
        temp3 = temp3 >> 8; 
        count3++;
      }
    }

    uint8_t overall[6];
    
    overall[0] = first[1];
    overall[1] = first[0];
    overall[2] = second[1];
    overall[3] = second[0];
    overall[4] = third[1];
    overall[5] = third[0];
    
   
   pCharacteristicOne->setValue(overall, 6);
   pCharacteristicOne->notify();
  }
   
 
}

void initilize_Bluetooth() {
  BLEDevice::init("ESP32");
  if (pServer != nullptr) {
    delete(pServer);
  }
  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID_ONE);

  // Create a BLE Characteristic
  pCharacteristicOne = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_ONE,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );
  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  pCharacteristicOne->addDescriptor(new BLE2902());

 
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID_ONE);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // set value to 0x00 to not advertise this parameter
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Waiting to connect...");
}

void adcHandler(void *pvParameter) {
  adcTaskHandle = xTaskGetCurrentTaskHandle();
  
  while (true) {
    uint32_t tcount = ulTaskNotifyTake(pdFALSE, pdMS_TO_TICKS(1000));
    if (test == 1) {
      send_data(abufa, abufb, abufc);
      test = 0;
    }
    esp_bt_mem_release(ESP_BT_MODE_BTDM);
    //Serial.println("Printing");
  }
}

void IRAM_ATTR onTimer() {
  
  if (deviceConnected == true && test == 0) {
    //portENTER_CRITICAL_ISR(&timerMux);
      abufa = analogRead(ADC6_pin_1);
      abufb = analogRead(ADC6_pin_2);
      abufc = analogRead(ADC6_pin_3);
      test = 1;
   // test = 1;
    // Notify adcTask that the buffer is full.
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    vTaskNotifyGiveFromISR(adcTaskHandle, &xHigherPriorityTaskWoken);
    if (xHigherPriorityTaskWoken) {
      portYIELD_FROM_ISR();
    }
    //portEXIT_CRITICAL_ISR(&timerMux);
    

    //Serial.println("Printing Ontimer");
    
  }
  
}

void setup() {
  Serial.begin(921600);
  initilize_Bluetooth();
  esp_bt_mem_release(ESP_BT_MODE_BTDM);
  xTaskCreate(adcHandler, "ADC_Task", 8192, NULL, 1, NULL);
  adcTimer = timerBegin(0, 80, true); // 80 MHz / 80 = 1 MHz hardware clock for easy figuring
  timerAttachInterrupt(adcTimer, &onTimer, true); // Attaches the handler function to the timer
  timerAlarmWrite(adcTimer, 1000, true); // Interrupts when counter == 200, i.e. 5000 times a second
  timerAlarmEnable(adcTimer);
}

void loop() {
  
 
}
