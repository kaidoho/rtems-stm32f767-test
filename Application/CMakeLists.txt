cmake_minimum_required (VERSION 3.10)
project(Demo)


set(CMAKE_EXE_LINKER_FLAGS "${EXE_LINKER_FLAGS}" CACHE INTERNAL "exe link flags" FORCE)


set(APP_SRC
  ${CMAKE_CURRENT_SOURCE_DIR}/Main/PreMain.c
  ${CMAKE_CURRENT_SOURCE_DIR}/Main/Main.cpp
)


add_executable(${CMAKE_PROJECT_NAME} ${APP_SRC})