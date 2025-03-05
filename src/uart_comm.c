// SPDX-FileCopyrightText: 2016 Frank Hunleth
// SPDX-FileCopyrightText: 2022 Jon Carstens
//
// SPDX-License-Identifier: Apache-2.0
//
#include "uart_comm.h"

/**
 * @brief Initialize UART configuration defaults
 *
 * The user is expected to really expected to provide
 * the configuration they want.
 *
 * @param config
 */
void uart_default_config(struct uart_config *config)
{
    config->active = true;
    config->speed = 9600;
    config->data_bits = 8;
    config->stop_bits = 1;
    config->parity = UART_PARITY_NONE;
    config->flow_control = UART_FLOWCONTROL_NONE;

    // RS485 unset by default
    config->rs485_user_configured = false;
    config->rs485_enabled = -1;
    config->rs485_rts_on_send = -1;
    config->rs485_rts_after_send = -1;
    config->rs485_rx_during_tx = -1;
    config->rs485_terminate_bus = -1;
    config->rs485_delay_rts_before_send = -1;
    config->rs485_delay_rts_after_send = -1;
}
