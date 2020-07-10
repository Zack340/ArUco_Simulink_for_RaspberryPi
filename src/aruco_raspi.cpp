#include "aruco_raspi.hpp"

cv::VideoCapture cap;
cv::Mat cameraMatrix;
cv::Mat distCoeffs;
cv::Ptr<cv::aruco::Dictionary> dictionary;
std::ostringstream vectorToMarker;
Settings stg;

int initialize(Settings &settings)
{
    stg = settings;
    dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::PREDEFINED_DICTIONARY_NAME(stg.dictionaryId));

    if (stg.isOutVectors)
    {
        cv::FileStorage fs(stg.calibFile, cv::FileStorage::READ);
        if (!fs.isOpened())
        {
            return 1;
        }
        fs["camera_matrix"] >> cameraMatrix;
        fs["distortion_coefficients"] >> distCoeffs;
        fs.release();
    }
    
    cap.open(stg.camSource);
    if (!cap.isOpened())
    {
        return 2;
    }
    cap.set(CV_CAP_PROP_FRAME_WIDTH, stg.capWidth);
    cap.set(CV_CAP_PROP_FRAME_HEIGHT, stg.capHeight);
//     cap.set(CV_CAP_PROP_FPS, stg.frameRate);
    
    return 0;
}

void step(Data &data)
{
    cv::Mat image;
    
    cap.grab();
    cap.retrieve(image);
    image.copyTo(data.image);
    cv::aruco::detectMarkers(image, dictionary, data.corners, data.ids);
    
    if (data.ids.size() > stg.arraySize)
    {
        data.ids.resize(stg.arraySize);
        data.corners.resize(stg.arraySize);
    }

    if (data.ids.size() > 0)
    {
        if (stg.isOutVectors)
        {
            cv::aruco::estimatePoseSingleMarkers(data.corners, stg.markLength,
                    cameraMatrix, distCoeffs, data.rvecs, data.tvecs);
        }
        
        if (stg.isOutImage)
        {
            cv::aruco::drawDetectedMarkers(data.image, data.corners, data.ids);
            
            if (stg.isOutVectors)
            {
                #pragma omp parallel for
                for(int i=0; i < data.ids.size(); i++)
                {
                    cv::aruco::drawAxis(data.image, cameraMatrix, distCoeffs,
                            data.rvecs[i], data.tvecs[i], stg.markLength);
                }
            }
        }
    }
}

void terminate()
{
    cap.release();
}