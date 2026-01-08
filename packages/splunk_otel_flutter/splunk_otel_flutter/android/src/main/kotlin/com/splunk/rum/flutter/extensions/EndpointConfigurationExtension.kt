/*
 * Copyright 2025 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.splunk.rum.flutter.extensions

import com.splunk.rum.flutter.GeneratedEndpointConfiguration
import com.splunk.rum.flutter.GeneratedStatus
import com.splunk.rum.integration.agent.api.EndpointConfiguration
import com.splunk.rum.integration.agent.api.Status
import java.net.URL
import java.util.IllegalFormatException

fun GeneratedEndpointConfiguration.toEndpointConfiguration(): EndpointConfiguration {
    if(sessionReplayEndpoint!=null && traceEndpoint!=null)
    {
        return EndpointConfiguration(URL(traceEndpoint),URL(sessionReplayEndpoint))
    }

    if(traceEndpoint!=null)
    {
        return EndpointConfiguration(URL(traceEndpoint))
    }

    if(realm!=null &&rumAccessToken!=null){
        return EndpointConfiguration(realm,rumAccessToken)
    }

    throw IllegalArgumentException("Endpoint configuration - Invalid parameter combination")
}

fun EndpointConfiguration.toGeneratedEndpointConfiguration(): GeneratedEndpointConfiguration {
    return GeneratedEndpointConfiguration(
        traceEndpoint = this.traceEndpoint.toString(),
        sessionReplayEndpoint = this.sessionReplayEndpoint?.toString(),
        realm = this.realm,
        rumAccessToken = this.rumAccessToken
    )
}