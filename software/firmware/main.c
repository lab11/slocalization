/**
  ******************************************************************************
  * @file    PWR/PWR_STANDBY/Src/main.c
  * @author  MCD Application Team
  * @version V1.5.0
  * @date    8-January-2016
  * @brief   This sample code shows how to use STM32L0xx PWR HAL API to enter
  *          and exit the standby mode with a wakeup pin or external reset.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; COPYRIGHT(c) 2016 STMicroelectronics</center></h2>
  *
  * Redistribution and use in source and binary forms, with or without modification,
  * are permitted provided that the following conditions are met:
  *   1. Redistributions of source code must retain the above copyright notice,
  *      this list of conditions and the following disclaimer.
  *   2. Redistributions in binary form must reproduce the above copyright notice,
  *      this list of conditions and the following disclaimer in the documentation
  *      and/or other materials provided with the distribution.
  *   3. Neither the name of STMicroelectronics nor the names of its contributors
  *      may be used to endorse or promote products derived from this software
  *      without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "main.h"

/** @addtogroup STM32L0xx_HAL_Examples
  * @{
  */

/** @addtogroup PWR_STANDBY
  * @{
  */

I2C_HandleTypeDef* I2CxHandle;

RTC_HandleTypeDef RtcHandle;

const uint8_t pn_sequence[8] = {0x04, 0x31, 0x4F, 0x47, 0x25, 0xBB, 0x35, 0x7E}; 
//const uint8_t pn_sequence[8] = {0x07, 0x92, 0xA6, 0x84, 0x5B, 0xF5, 0xC6, 0x76}; 
//const uint8_t pn_sequence[8] = {0x03, 0xA3, 0xE9, 0xC3, 0x7E, 0x4E, 0xF3, 0x08}; 
//const uint8_t pn_sequence[8] = {0x87, 0xF8, 0x1C, 0x05, 0x08, 0x41, 0xD6, 0x44}; 
//const uint8_t pn_sequence[8] = {0xC5, 0xD5, 0xE6, 0xE6, 0x33, 0x46, 0x44, 0xE2}; 
//const uint8_t pn_sequence[8] = {0x64, 0xC3, 0x1B, 0x97, 0xAE, 0xC5, 0x8D, 0xB0}; 
//const uint8_t pn_sequence[8] = {0xB4, 0x48, 0x65, 0x2F, 0x60, 0x04, 0x69, 0x18}; 
//const uint8_t pn_sequence[8] = {0xDC, 0x0D, 0xDA, 0x73, 0x07, 0x64, 0x9B, 0x4C};
const uint8_t pn_sequence_length = 63;

/* Pin definitions */
#define DFF_PORT GPIOB
#define DFF_CLK_PIN GPIO_PIN_1
#define DFF_DATA0_PIN GPIO_PIN_0
#define DFF_DATA1_PIN GPIO_PIN_4

#define RESET_COUNT_REGISTER 2
#define I2C_ADDRESS 0xD2

#define I2C_TIMING_100KHZ 0x10A13E56
  
/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void SystemPower_Config(void);

void Ambiq_0805_Command(uint8_t command, uint8_t data_byte){
  uint8_t tx_buffer[2];
  tx_buffer[0] = command;
  tx_buffer[1] = data_byte;
  while(HAL_I2C_Master_Transmit_IT(I2CxHandle, (uint16_t)I2C_ADDRESS, (uint8_t*)tx_buffer, 2) != HAL_OK){ /* TODO: Add some error handling? */ };
  while(HAL_I2C_GetState(I2CxHandle) != HAL_I2C_STATE_READY){}
}

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
int Reset_Handler(void)
{
  uint32_t reset_count;
  uint32_t pn_sequence_byte;
  uint8_t pn_sequence_bit;
  /* STM32L0xx HAL library initialization:
       - Configure the Flash prefetch, Flash preread and Buffer caches
       - Systick timer is configured by default as source of time base, but user 
             can eventually implement his proper time base source (a general purpose 
             timer for example or other time source), keeping in mind that Time base 
             duration should be kept 1ms since PPP_TIMEOUT_VALUEs are defined and 
             handled in milliseconds basis.
       - Low Level Initialization
     */

  //Commented out during speed-up work; doesn't seem to make a difference
  //HAL_Init();

  if (! (__HAL_PWR_GET_FLAG(PWR_FLAG_SB) != RESET) ) {
    /* Configure the system clock to 2 MHz */
    SystemClock_Config();
  }


  /* System Power Configuration */
  SystemPower_Config()  ;

  // Configure DFF outputs
  __HAL_RCC_GPIOB_CLK_ENABLE();

  GPIO_InitTypeDef  GPIO_InitStruct;
  // Configure DFF clock pin
  GPIO_InitStruct.Pin = DFF_CLK_PIN;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
  HAL_GPIO_Init(DFF_PORT, &GPIO_InitStruct);
  HAL_GPIO_WritePin(DFF_PORT, DFF_CLK_PIN, GPIO_PIN_RESET);

  // Configure DFF0 Data
  GPIO_InitStruct.Pin = DFF_DATA0_PIN;
  HAL_GPIO_Init(DFF_PORT, &GPIO_InitStruct);

  // Configure DFF1 Data
  GPIO_InitStruct.Pin = DFF_DATA1_PIN;
  HAL_GPIO_Init(DFF_PORT, &GPIO_InitStruct);

  RtcHandle.Instance = RTC;
  __HAL_RCC_PWR_CLK_ENABLE();
  HAL_PWR_EnableBkUpAccess();
 
  /* Check if the system was resumed from Standby mode */ 
  if (__HAL_PWR_GET_FLAG(PWR_FLAG_SB) != RESET)
  {
    reset_count = HAL_RTCEx_BKUPRead(&RtcHandle, RESET_COUNT_REGISTER);
    reset_count++;

    /* Clear Standby flag */
    __HAL_PWR_CLEAR_FLAG(PWR_FLAG_SB); 

  } else {
    I2C_HandleTypeDef I2CxHandleLocal = {0};

    /* Insert 5 seconds delay */
    HAL_Delay(5000);

    I2CxHandleLocal.Instance = I2Cx;
    I2CxHandleLocal.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
    I2CxHandleLocal.Init.Timing = I2C_TIMING_100KHZ;
    I2CxHandleLocal.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
    I2CxHandleLocal.Init.OwnAddress2Masks = I2C_OA2_NOMASK;
    I2CxHandleLocal.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
    I2CxHandleLocal.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
    I2CxHandleLocal.Init.OwnAddress1 = I2C_ADDRESS;
    I2CxHandleLocal.Init.OwnAddress2 = 0xFE;

    I2CxHandle = &I2CxHandleLocal;
    if(HAL_I2C_Init(I2CxHandle) != HAL_OK){ /* TODO: Add some error handling? */ }

    reset_count = 0;

    Ambiq_0805_Command(0x13, 0x8F);
    Ambiq_0805_Command(0x12, 0xA4);
    Ambiq_0805_Command(0x11, 0x03);
    Ambiq_0805_Command(0x18, 0x3C);
  }

  // Write new reset count to backup register
  HAL_RTCEx_BKUPWrite(&RtcHandle, RESET_COUNT_REGISTER, reset_count);

  // Get current PN bit
  reset_count %= (pn_sequence_length << 1);
  pn_sequence_byte = reset_count >> 4;
  pn_sequence_bit = (pn_sequence[pn_sequence_byte] & (0x80 >> ((reset_count >> 1) & 7))) > 0;
  pn_sequence_bit = (reset_count & 1) ^ pn_sequence_bit;
  if(pn_sequence_bit){
    HAL_GPIO_WritePin(DFF_PORT, DFF_DATA0_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(DFF_PORT, DFF_DATA1_PIN, GPIO_PIN_SET);
    HAL_GPIO_WritePin(DFF_PORT, DFF_CLK_PIN, GPIO_PIN_SET);
  } else {
    HAL_GPIO_WritePin(DFF_PORT, DFF_DATA0_PIN, GPIO_PIN_SET);
    HAL_GPIO_WritePin(DFF_PORT, DFF_DATA1_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(DFF_PORT, DFF_CLK_PIN, GPIO_PIN_SET);
  }

 /* The Following Wakeup sequence is highly recommended prior to each Standby mode entry
    mainly when using more than one wakeup source this is to not miss any wakeup event.
     - Disable all used wakeup sources,
     - Clear all related wakeup flags, 
     - Re-enable all used wakeup sources,
     - Enter the Standby mode.
  */

  /* Disable all used wakeup sources: PWR_WAKEUP_PIN1 */
  HAL_PWR_DisableWakeUpPin(PWR_WAKEUP_PIN1);

  /* Clear all related wakeup flags*/
  __HAL_PWR_CLEAR_FLAG(PWR_FLAG_WU);
    
  /* Enable WakeUp Pin PWR_WAKEUP_PIN1 connected to PA.02 (Arduino A7) */
  HAL_PWR_EnableWakeUpPin(PWR_WAKEUP_PIN1);

  /* Enter the Standby mode */
  HAL_PWR_EnterSTANDBYMode();

  /* This code will never be reached! */
  while (1)
  {
  }
}

/**
  * @brief  System Clock Configuration
  *         The system Clock is configured as follow : 
  *            System Clock source            = MSI
  *            SYSCLK(Hz)                     = 2000000
  *            HCLK(Hz)                       = 2000000
  *            AHB Prescaler                  = 1
  *            APB1 Prescaler                 = 1
  *            APB2 Prescaler                 = 1
  *            Flash Latency(WS)              = 0
  *            Main regulator output voltage  = Scale3 mode
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  
  /* Enable MSI Oscillator */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_5;
  RCC_OscInitStruct.MSICalibrationValue=0x00;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct)!= HAL_OK)
  {
    /* Initialization Error */
    while(1); 
  }
  
  /* Select MSI as system clock source and configure the HCLK, PCLK1 and PCLK2 
     clocks dividers */
  RCC_ClkInitStruct.ClockType = (RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2);
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_MSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;  
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;  
  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0)!= HAL_OK)
  {
    /* Initialization Error */
    while(1); 
  }
  /* Enable Power Control clock */
  __HAL_RCC_PWR_CLK_ENABLE();
  
  /* The voltage scaling allows optimizing the power consumption when the device is 
     clocked below the maximum system frequency, to update the voltage scaling value 
     regarding system frequency refer to product datasheet.  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE3);
  
  /* Disable Power Control clock */
  __HAL_RCC_PWR_CLK_DISABLE();
  
}


/**
  * @brief  This function is executed in case of error occurrence.
  * @param  None
  * @retval None
  */
void Error_Handler(void)
{
  while (1)
  {
  }
}

/**
  * @brief  System Power Configuration
  *         The system Power is configured as follow : 
  *            + VREFINT OFF, with fast wakeup enabled
  *            + No IWDG
  *            + Wakeup using PWR_WAKEUP_PIN1
  * @param None
  * @retval None
  */
static void SystemPower_Config(void)
{
  /* Enable Power Control clock */
  __HAL_RCC_PWR_CLK_ENABLE();

  /* Enable Ultra low power mode */
  HAL_PWREx_EnableUltraLowPower();
  
  /* Enable the fast wake up from Ultra low power mode */
  HAL_PWREx_EnableFastWakeUp();
}

/**
  * @brief SYSTICK callback
  * @param None
  * @retval None
  */
void HAL_SYSTICK_Callback(void)
{
  HAL_IncTick();
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */

  /* Infinite loop */
  while (1)
  {
  }
}
#endif

/**
  * @}
  */

/**
  * @}
  */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
