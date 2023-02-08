// Copyright (c) 2020 - 2021 by Robert Bosch GmbH All rights reserved.
// Copyright (c) 2020 - 2021 by Apex.AI Inc. All rights reserved.
// Copyright (c) 2023 by NXP. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

#include <chrono>
#include <cstdint>
#include <iostream>
#include <mutex>

#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"
#include "task.h"

#include "iceoryx_hoofs/log/logger.hpp"
#include "iceoryx_posh/iceoryx_posh_config.hpp"
#include "iceoryx_posh/iceoryx_posh_types.hpp"
#include "iceoryx_posh/internal/roudi/roudi.hpp"
#include "iceoryx_posh/popo/publisher.hpp"
#include "iceoryx_posh/popo/subscriber.hpp"
#include "iceoryx_posh/roudi/iceoryx_roudi_components.hpp"
#include "iceoryx_posh/runtime/posh_runtime_single_process.hpp"

#include "console.h"

// Custom logger
class MyLogger : public iox::log::Logger {
public:
  static void init() {
    static MyLogger myLogger;
    iox::log::Logger::setActiveLogger(myLogger);
    iox::log::Logger::init(
        iox::log::logLevelFromEnvOr(iox::log::LogLevel::DEBUG));
  }

private:
  std::mutex _mutex;

  void flush() noexcept override {
    std::lock_guard<std::mutex> lock{_mutex};
    print(iox::log::Logger::getLogBuffer().buffer);
    print("\n");
    iox::log::Logger::assumeFlushed();
  }
};

// Custom error handler
class MyErrorHandler : iox::ErrorHandler {
public:
  static void init() noexcept { handler = {errorHandler}; }

private:
  static void errorHandler(const uint32_t err, const char *errName,
                           const iox::ErrorLevel level) noexcept {
    configASSERT(false);
  }
};

struct TransmissionData_t {
  uint64_t counter;
};

constexpr std::chrono::milliseconds CYCLE_TIME{500};

void publisherThr() {
  iox::popo::PublisherOptions publisherOptions;
  iox::popo::Publisher<TransmissionData_t> publisher{
      iox::capro::ServiceDescription{"Free", "RTOS", "Demo"}, publisherOptions};
  print("Publisher created!\n");

  uint64_t counter{0};
  while (true) {
    std::this_thread::sleep_for(CYCLE_TIME);

    publisher.loan()
        .and_then([&](auto &sample) {
          sample->counter = counter;
          sample.publish();
          print("Sample ");
          print(counter);
          print(" published!\n");
          counter++;
        })
        .or_else([&](auto &result) { configASSERT(false); });
  }
}

void subscriberThr() {
  iox::popo::SubscriberOptions options;
  options.queueCapacity = 1U;
  iox::popo::Subscriber<TransmissionData_t> subscriber{
      iox::capro::ServiceDescription{"Free", "RTOS", "Demo"}, options};
  print("Subscriber created!\n");

  while (true) {
    if (iox::SubscribeState::SUBSCRIBED == subscriber.getSubscriptionState()) {
      bool hasMoreSamples{true};

      do {
        subscriber.take()
            .and_then([&](auto &sample) {
              print("Sample ");
              print(sample->counter);
              print(" received!\n");
            })
            .or_else([&](auto &result) {
              hasMoreSamples = false;
              if (result != iox::popo::ChunkReceiveResult::NO_CHUNK_AVAILABLE) {
                configASSERT(false);
              }
            });
      } while (hasMoreSamples);
    }

    std::this_thread::yield();
  }
}

int main(int, char **) {
  print("Starting main ...\n");
  MyLogger::init();
  MyErrorHandler::init();

  print("Configuring RouDi memory pool...\n");
  iox::RouDiConfig_t roudiConfig = iox::RouDiConfig_t().setDefaults();
  auto &mempoolConfig =
      roudiConfig.m_sharedMemorySegments.front().m_mempoolConfig;
  mempoolConfig.m_mempoolConfig.clear();
  mempoolConfig.m_mempoolConfig.push_back(
      {128, 5}); // 5 buffers, each 128 bytes
  iox::roudi::IceOryxRouDiComponents roudiComponents(roudiConfig);

  print("Running RouDi...\n");
  constexpr bool TERMINATE_APP_IN_ROUDI_DTOR_FLAG = false;
  iox::roudi::RouDi roudi(
      roudiComponents.rouDiMemoryManager, roudiComponents.portManager,
      iox::roudi::RouDi::RoudiStartupParameters{
          iox::roudi::MonitoringMode::OFF, TERMINATE_APP_IN_ROUDI_DTOR_FLAG});

  // Delay to make time for roudi to initialize everything
  vTaskDelay(pdMS_TO_TICKS(200));

  // create a single process runtime for inter thread communication
  print("Initializing posh runtime...\n");
  iox::runtime::PoshRuntimeSingleProcess runtime("freertosExample");

  print("Initializing publisher thread...\n");
  std::thread publisherThread(publisherThr);

  print("Initializing subscriber thread...\n");
  std::thread subscriberThread(subscriberThr);

  publisherThread.detach();
  subscriberThread.detach();

  vTaskDelete(NULL);
  return 0;
}
