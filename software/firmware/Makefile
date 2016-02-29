PROJECT_NAME = $(shell basename "$(realpath ./)")

#List all of the application source files that need to be compiled
#############################################
APPLICATION_SRCS = $(notdir $(wildcard ./*.c))
APPLICATION_SRCS += led.c
APPLICATION_SRCS += timer.c
APPLICATION_SRCS += prng.c
APPLICATION_SRCS += delay.c

APPLICATION_SRCS += stm32f0xx_gpio.c
APPLICATION_SRCS += stm32f0xx_rcc.c
APPLICATION_SRCS += stm32f0xx_i2c.c
APPLICATION_SRCS += stm32f0xx_dma.c
APPLICATION_SRCS += stm32f0xx_misc.c
APPLICATION_SRCS += stm32f0xx_tim.c
APPLICATION_SRCS += stm32f0xx_spi.c
APPLICATION_SRCS += stm32f0xx_pwr.c
APPLICATION_SRCS += stm32f0xx_exti.c
APPLICATION_SRCS += stm32f0xx_syscfg.c

APPLICATION_SRCS += stm32f0xx_i2c_cpal.c
APPLICATION_SRCS += stm32f0xx_i2c_cpal_hal.c

APPLICATION_SRCS += deca_device.c
APPLICATION_SRCS += deca_params_init.c

CFLAGS += 
LDFLAGS += -lm

#The exact STM part number All CAPS
############################################
DEVICE ?= STM32L051K6
DEVICE_FAMILY ?= STM32L051

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
