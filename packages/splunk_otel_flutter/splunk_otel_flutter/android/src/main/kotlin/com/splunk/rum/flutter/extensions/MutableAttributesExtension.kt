package com.splunk.rum.flutter.extensions

import com.splunk.rum.flutter.GeneratedMutableAttributeBool
import com.splunk.rum.flutter.GeneratedMutableAttributeDouble
import com.splunk.rum.flutter.GeneratedMutableAttributeInt
import com.splunk.rum.flutter.GeneratedMutableAttributeListBool
import com.splunk.rum.flutter.GeneratedMutableAttributeListDouble
import com.splunk.rum.flutter.GeneratedMutableAttributeListInt
import com.splunk.rum.flutter.GeneratedMutableAttributeListString
import com.splunk.rum.flutter.GeneratedMutableAttributeString
import com.splunk.rum.flutter.GeneratedMutableAttributes
import com.splunk.rum.integration.agent.common.attributes.MutableAttributes
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes

fun Attributes.toGeneratedMutableAttributes(): GeneratedMutableAttributes {
    val generatedMap = mutableMapOf<String, Any?>()
    this.forEach { key, value ->
        generatedMap[key.key] = value.wrapIntoGeneratedMutableAttribute()
    }

    return GeneratedMutableAttributes(generatedMap)
}

fun GeneratedMutableAttributes.toMutableAttributes(): MutableAttributes {
    val mutableAttributes = MutableAttributes()
    this.attributes.forEach { (key, generatedValueWrapper) ->
        when (generatedValueWrapper) {
            is GeneratedMutableAttributeInt -> mutableAttributes[key] = generatedValueWrapper.value
            is GeneratedMutableAttributeDouble -> mutableAttributes[key] = generatedValueWrapper.value
            is GeneratedMutableAttributeString -> mutableAttributes[key] = generatedValueWrapper.value
            is GeneratedMutableAttributeBool -> mutableAttributes[key] = generatedValueWrapper.value
            is GeneratedMutableAttributeListInt -> mutableAttributes.set(AttributeKey.longArrayKey(key), generatedValueWrapper.value)
            is GeneratedMutableAttributeListDouble -> mutableAttributes.set(AttributeKey.doubleArrayKey(key), generatedValueWrapper.value)
            is GeneratedMutableAttributeListString -> mutableAttributes.set(AttributeKey.stringArrayKey(key), generatedValueWrapper.value)
            is GeneratedMutableAttributeListBool -> mutableAttributes.set(AttributeKey.booleanArrayKey(key), generatedValueWrapper.value)
            null -> {}
            else -> throw IllegalArgumentException("Unsupported GeneratedMutableAttribute type for key $key: ${generatedValueWrapper.javaClass}")
        }
    }

    return mutableAttributes
}

fun Any.extractPrimitiveValueFromGenerated(): Any {
    return when (this) {
        is GeneratedMutableAttributeInt -> this.value
        is GeneratedMutableAttributeDouble -> this.value
        is GeneratedMutableAttributeString -> this.value
        is GeneratedMutableAttributeBool -> this.value
        is GeneratedMutableAttributeListInt -> this.value
        is GeneratedMutableAttributeListDouble -> this.value
        is GeneratedMutableAttributeListString -> this.value
        is GeneratedMutableAttributeListBool -> this.value
        else -> throw IllegalArgumentException("Unsupported GeneratedMutableAttribute type: ${this.javaClass}")
    }
}

fun Any.wrapIntoGeneratedMutableAttribute(): Any {
    return when (this) {
        is Long -> GeneratedMutableAttributeInt(this)
        is Int -> GeneratedMutableAttributeInt(this.toLong())
        is Double -> GeneratedMutableAttributeDouble(this)
        is String -> GeneratedMutableAttributeString(this)
        is Boolean -> GeneratedMutableAttributeBool(this)
        is List<*> -> {
            if (this.all { it is Long }) {
                GeneratedMutableAttributeListInt((this as List<Long>))
            } else if (this.all { it is Int }) {
                GeneratedMutableAttributeListInt(this as List<Long>)
            } else if (this.all { it is Double }) {
                GeneratedMutableAttributeListDouble(this as List<Double>)
            } else if (this.all { it is String }) {
                GeneratedMutableAttributeListString(this as List<String>)
            } else if (this.all { it is Boolean }) {
                GeneratedMutableAttributeListBool(this as List<Boolean>)
            } else {
                throw IllegalArgumentException("Unsupported List type for wrapping into GeneratedMutableAttribute: ${this.javaClass}")
            }
        }
        else -> throw IllegalArgumentException("Unsupported primitive type for wrapping into GeneratedMutableAttribute: ${this.javaClass}")
    }
}