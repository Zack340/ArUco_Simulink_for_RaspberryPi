/* 
 *  	Author : Eisuke Matsuzaki
 *  	Created on : 2020/07/10
 *  	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
 *      Released under the GNU license
 * 
 *      ArUco wrapper for Raspberry Pi
 */ 

#ifndef _ARUCO_RASPI_WRAPPER_HPP_
#define _ARUCO_RASPI_WRAPPER_HPP_
#include "rtwtypes.h"
#include <iostream>
#include <cstdlib>
#include <string>
#include <vector>
#include <omp.h>

struct Parameters{
    real32_T markLength;
    real32_T samplingTime;
    uint8_T dictionaryId;
    uint8_T arraySize;
    uint16_T capWidth;
    uint16_T capHeight;
    uint16_T imgWidth;
    uint16_T imgHeight;
    int32_T camSource;
    boolean_T isOutCorners;
    boolean_T isOutVectors;
    boolean_T isOutImage;
};

void setup(Parameters *params, char *calibFile, uint8_T charSize);
boolean_T getData(int32_T *ids, real32_T *corners, double *rvecs, double *tvecs, uint8_T *image);
void release();
void errorMessage(int exception);

#endif //_ARUCO_RASPI_WRAPPER_HPP_