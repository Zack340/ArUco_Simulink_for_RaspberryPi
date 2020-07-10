#include "aruco_raspi_wrapper.hpp"
#include "aruco_raspi.hpp"

Parameters *prm;

void setup(Parameters *params, char *calibFile, uint8_T charSize)
{
    prm = params;
    
    Settings settings;
    settings.markLength = params->markLength;
    settings.samplingTime = params->samplingTime;
    settings.dictionaryId = params->dictionaryId;
    settings.arraySize = params->arraySize;
    settings.capWidth = params->capWidth;
    settings.capHeight = params->capHeight;
    settings.camSource = params->camSource;
    settings.isOutCorners = params->isOutCorners;
    settings.isOutVectors = params->isOutVectors;
    settings.isOutImage = params->isOutImage;
    settings.calibFile.assign(calibFile, charSize);
    
    int exception = initialize(settings);
    errorMessage(exception);
}

boolean_T getData(int32_T *ids, real32_T *corners, double *rvecs, double *tvecs, uint8_T *image)
{
    Data data;
    step(data);
    
    for (uint8_T i = 0; i < data.ids.size(); ++i)
    {
        ids[i] = data.ids[i];
    }
    
    if (prm->isOutCorners)
    {
        for (uint8_T i = 0; i < data.ids.size(); ++i)
        {
            for (uint8_T j = 0; j < 4; ++j)
            {
                corners[i + prm->arraySize * j + prm->arraySize * 4 * 0] = data.corners[i][j].x;
                corners[i + prm->arraySize * j + prm->arraySize * 4 * 1] = data.corners[i][j].y;
            }
        }
    }
    
    if (prm->isOutVectors)
    {
        for (uint8_T i = 0; i < data.ids.size(); ++i)
        {
            for (uint8_T j = 0; j < 3; ++j)
            {
                rvecs[i + prm->arraySize * j] = data.rvecs[i][j];
                tvecs[i + prm->arraySize * j] = data.tvecs[i][j];
            }
        }
    }
    
    if (prm->isOutImage)
    {
        cv::Mat copyImage;
        if (prm->capWidth != prm->imgWidth || prm->capHeight != prm->imgHeight)
        {
            copyImage = cv::Mat::zeros(prm->imgHeight, prm->imgWidth, CV_8UC3);
            resize(data.image, copyImage, copyImage.size());
        }
        else
        {
            data.image.copyTo(copyImage);
        }
        
        #pragma omp parallel for
        for (uint16_T i = 0; i < prm->imgWidth; ++i)
        {
            #pragma omp parallel for
            for (uint16_T j = 0; j < prm->imgHeight; ++j)
            {
                image[i + prm->imgWidth * j + prm->imgWidth * prm->imgHeight * 0] =
                            copyImage.at<cv::Vec3b>(j, i)[2];
                image[i + prm->imgWidth * j + prm->imgWidth * prm->imgHeight * 1] =
                            copyImage.at<cv::Vec3b>(j, i)[1];
                image[i + prm->imgWidth * j + prm->imgWidth * prm->imgHeight * 2] =
                            copyImage.at<cv::Vec3b>(j, i)[0];
            }
        }
    }
       
    return data.ids.size() > 0;
}

void release()
{
    terminate();
}

void errorMessage(int exception)
{
    switch (exception)
    {
        case 0:
            return;
        case 1:
            std::cout << "\nError : Failed to open the calibration file.\nCheck the file name or contents." << std::endl;
            exit(1);
        case 2:
            std::cout << "\nError : Failed to open the Camera.\nCheck the camera source or connection." << std::endl;
            exit(1);
        default:
            return;    
    }          
}