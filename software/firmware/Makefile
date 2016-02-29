PROJECT_NAME = $(shell basename "$(realpath ./)")

#List all of the application source files that need to be compiled
#############################################
APPLICATION_SRCS = $(notdir $(wildcard ./*.c))

APPLICATION_SRCS += stm32l0xx_hal.c
APPLICATION_SRCS += stm32l0xx_hal_pwr.c
APPLICATION_SRCS += stm32l0xx_hal_pwr_ex.c
APPLICATION_SRCS += stm32l0xx_hal_gpio.c
APPLICATION_SRCS += stm32l0xx_hal_cortex.c
APPLICATION_SRCS += stm32l0xx_hal_rcc.c

CFLAGS += -D STM32L051xx
LDFLAGS += -lm

#The exact STM part number All CAPS
############################################
DEVICE ?= STM32L051K8
DEVICE_FAMILY ?= STM32L051xx

CFLAGS += -Wall -Wextra -g

#The install locations of the STM Standard library
#################################################
LIBRARY_START_PATH ?= ../stm32l0-base/sdk/STM32Cube_FW_LO_V1.5.0/

#The location of the gcc setup template
################################################
TEMPLATE_PATH ?= ../stm32l0-base/stm32l0xx-gcc-setup/template/

#Any places that you put custom header files
###############################################
LIBRARY_PATHS += ../include

#Any places that you put custom source files
##############################################
SOURCE_PATHS += ../source

ifndef LIBRARY_START_PATH
$(error An LIBRARY_START_PATH must be defined. Edit Makefile to define a valid LIBRARY_PATH)
endif

CFLAGS += -Os
GDB_PORT_NUMBER = 2331

include $(TEMPLATE_PATH)Makefile
