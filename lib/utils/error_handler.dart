import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ErrorHandler {
  /// Parse exception and return user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    // Convert error to string for parsing
    final errorStr = error.toString();
    
    if (error is SocketException) {
      return 'Unable to connect. Please check your internet connection.';
    } else if (error is HttpException) {
      return 'Unable to connect to the server. Please try again later.';
    } else if (error is FormatException) {
      return 'Invalid data received. Please try again.';
    } else if (error is http.ClientException) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('Connection refused') || 
               errorStr.contains('errno = 111')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    } else if (errorStr.contains('Connection timed out')) {
      return 'Connection timed out. Please check your internet connection.';
    } else if (errorStr.contains('Not authenticated') || 
               errorStr.contains('Authentication required')) {
      return 'Session expired. Please login again.';
    } else if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return 'Session expired. Please login again.';
    } else if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
      return 'Access denied. You don\'t have permission to access this.';
    } else if (errorStr.contains('404') || errorStr.contains('Not Found')) {
      return 'Content not found.';
    } else if (errorStr.contains('500') || errorStr.contains('Internal Server Error')) {
      return 'Server error. Please try again later.';
    } else if (errorStr.contains('503') || errorStr.contains('Service Unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else if (errorStr.contains('Failed to load')) {
      // Generic "Failed to load" messages - make them user-friendly
      return 'Unable to load data. Please try again.';
    } else if (errorStr.contains('Exception:')) {
      // Strip out the "Exception: " prefix and any technical details
      String message = errorStr.replaceFirst('Exception: ', '');
      // Remove any URLs, ports, addresses from the message
      message = message.replaceAll(RegExp(r'http[s]?://[^\s]+'), '');
      message = message.replaceAll(RegExp(r'address\s*=\s*[0-9.]+'), '');
      message = message.replaceAll(RegExp(r'port\s*=\s*[0-9]+'), '');
      message = message.replaceAll(RegExp(r'errno\s*=\s*[0-9]+'), '');
      message = message.replaceAll(RegExp(r'uri=[^\s,)]+'), '');
      message = message.replaceAll(RegExp(r'\([^)]*Connection refused[^)]*\)'), '');
      message = message.replaceAll(RegExp(r'ClientException with SocketException:'), '');
      message = message.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // If the cleaned message is too long or still contains technical terms, use generic message
      if (message.length > 100 || 
          message.contains('SocketException') ||
          message.contains('ClientException') ||
          message.contains('OS Error')) {
        return 'Unable to connect. Please check your internet connection.';
      }
      
      return message.isNotEmpty ? message : 'Something went wrong. Please try again.';
    }
    
    // Default message for unknown errors
    return 'Something went wrong. Please try again.';
  }

  /// Check if error is authentication related
  static bool isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('not authenticated') ||
           errorStr.contains('authentication required') ||
           errorStr.contains('401') ||
           errorStr.contains('unauthorized') ||
           errorStr.contains('session expired') ||
           errorStr.contains('invalid token');
  }

  /// Check if error is network related
  static bool isNetworkError(dynamic error) {
    final errorStr = error.toString();
    return error is SocketException ||
           error is HttpException ||
           error is http.ClientException ||
           errorStr.contains('Connection refused') ||
           errorStr.contains('Connection timed out') ||
           errorStr.contains('errno = 111') ||
           errorStr.contains('Network is unreachable');
  }

  /// Get appropriate icon for error type
  static IconData getErrorIcon(dynamic error) {
    if (isAuthError(error)) {
      return Icons.lock_outline;
    } else if (isNetworkError(error)) {
      return Icons.wifi_off;
    } else if (error.toString().contains('404')) {
      return Icons.search_off;
    } else {
      return Icons.error_outline;
    }
  }

  /// Get appropriate color for error type
  static Color getErrorColor(dynamic error) {
    if (isAuthError(error)) {
      return Colors.orange;
    } else if (isNetworkError(error)) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  /// Build error widget with icon and message
  static Widget buildErrorWidget({
    required dynamic error,
    required VoidCallback onRetry,
    VoidCallback? onLogin,
    String? customMessage,
  }) {
    final message = customMessage ?? getUserFriendlyMessage(error);
    final isAuth = isAuthError(error);
    final icon = getErrorIcon(error);
    final color = getErrorColor(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isAuth && onLogin != null)
              ElevatedButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login),
                label: const Text('Login Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    final message = customMessage ?? getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              getErrorIcon(error),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: getErrorColor(error),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
