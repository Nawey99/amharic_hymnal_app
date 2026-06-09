# Custom plugin processing that excludes flutter_secure_storage_windows
# This works around Windows build errors with flutter_secure_storage (atlstr.h missing)
# The app uses SharedPreferences fallback on Windows anyway

# Read the plugin list from generated file but don't execute its foreach loop
# We'll define the plugin list manually with the problematic plugin excluded
set(FLUTTER_PLUGIN_LIST
  # flutter_secure_storage_windows  # Excluded due to Windows build issues (atlstr.h)
  share_plus
  sqlite3_flutter_libs
  url_launcher_windows
)

set(FLUTTER_FFI_PLUGIN_LIST)

# Process the filtered plugin list
set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
