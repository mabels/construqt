cmake_minimum_required(VERSION 2.8.4)
project(relaytor)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
    easylogging++.h
    relaytor.cpp)

add_executable(relaytor ${SOURCE_FILES})