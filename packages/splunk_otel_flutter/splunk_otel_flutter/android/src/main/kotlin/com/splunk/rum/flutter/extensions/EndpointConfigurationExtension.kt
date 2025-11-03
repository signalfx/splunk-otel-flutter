package com.splunk.rum.flutter.extensions

import com.splunk.rum.flutter.GeneratedEndpointConfiguration
import com.splunk.rum.flutter.GeneratedStatus
import com.splunk.rum.integration.agent.api.EndpointConfiguration
import com.splunk.rum.integration.agent.api.Status
import java.net.URL
import java.util.IllegalFormatException

fun GeneratedEndpointConfiguration.toEndpointConfiguration(): EndpointConfiguration {
    if(logsEndpoint!=null && tracesEndpoint!=null)
    {
        return EndpointConfiguration(URL(tracesEndpoint),URL(logsEndpoint))
    }
    if(tracesEndpoint!=null)
    {
        return EndpointConfiguration(URL(tracesEndpoint))
    }

    if(realm!=null &&rumAccessToken!=null){
        return EndpointConfiguration(realm,rumAccessToken)
    }

    throw IllegalArgumentException("Invalid parameter combination")
}

fun EndpointConfiguration.toGeneratedEndpointConfiguration(): GeneratedEndpointConfiguration {
    return GeneratedEndpointConfiguration(
        tracesEndpoint = this.tracesEndpoint?.toString(),
        logsEndpoint = this.logsEndpoint?.toString(),
        realm = this.realm,
        rumAccessToken = this.rumAccessToken
    )
}