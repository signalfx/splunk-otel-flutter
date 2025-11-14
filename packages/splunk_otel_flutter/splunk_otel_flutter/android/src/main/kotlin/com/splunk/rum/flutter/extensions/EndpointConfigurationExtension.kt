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
        traceEndpoint = this.traceEndpoint?.toString(),
        sessionReplayEndpoint = this.sessionReplayEndpoint?.toString(),
        realm = this.realm,
        rumAccessToken = this.rumAccessToken
    )
}