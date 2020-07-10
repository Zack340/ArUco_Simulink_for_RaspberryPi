/* 
 *  	Author : Eisuke Matsuzaki
 *  	Created on : 2020/07/10
 *  	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
 *      Released under the GNU license
 * 
 *      ArUco for Raspberry Pi
 */ 

#ifndef _ARUCO_RASPI_HPP_
#define _ARUCO_RASPI_HPP_
#include <opencv2/opencv.hpp>
#include <opencv2/aruco.hpp>
#include <iostream>
#include <cstdlib>
#include <string>
#include <omp.h>

struct Settings
{
    float markLength;
    float samplingTime;
    unsigned char dictionaryId;
    unsigned char arraySize;
    unsigned short capWidth;
    unsigned short capHeight;
    int camSource;
    bool isOutCorners;
    bool isOutVectors;
    bool isOutImage;
    std::string calibFile;
};

struct Data
{
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f> > corners;
    std::vector<cv::Vec3d> rvecs;
    std::vector<cv::Vec3d> tvecs;
    cv::Mat image;
};

int initialize(Settings &settings);
void step(Data &data);
void terminate();

#endif //_ARUCO_RASPI_HPP_
