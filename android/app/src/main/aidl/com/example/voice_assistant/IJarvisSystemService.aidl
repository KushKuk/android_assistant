// IJarvisSystemService.aidl
package com.example.voice_assistant;

interface IJarvisSystemService {
    String getServiceVersion();
    boolean ping();
    String getSystemStatus();
    String executeSystemOperation(String operation, String action, String args);
}