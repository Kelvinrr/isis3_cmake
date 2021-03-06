#===========================================================================
# Code for installing the third part libraries to the output folder.
#===========================================================================

# Library portion of the installation
function(install_third_party_libs)



  # Where all the library files will go
  set(installLibFolder "${CMAKE_INSTALL_PREFIX}/3rdParty/lib")

  # TEMPORARY CODE TO INSTALL ALL FILES FROM V007/lib into 3rdParty/lib
  if(APPLE)
    install(DIRECTORY "/opt/usgs/v007/3rdParty/lib" DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(DIRECTORY "/opt/usgs/v007/ports/lib" DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(DIRECTORY "/opt/usgs/v007/proprietary/lib" DESTINATION ${CMAKE_INSTALL_PREFIX})
  else()
    install(DIRECTORY "/usgs/pkgs/local/v007/lib" DESTINATION ${CMAKE_INSTALL_PREFIX})
  endif()

  # Loop through all the library files in our list
  foreach(library ${ALLLIBS})
    get_filename_component(extension ${library} EXT)
    if ("${extension}" STREQUAL ".so" OR "${extension}" STREQUAL ".dylib" )
      #get path to library in libararypath
      get_filename_component(librarypath ${library} PATH)

      # Copy file to output directory
      file(RELATIVE_PATH relPath "${thirdPartyDir}/lib" ${library})

      # Check if the file is a symlink
      execute_process(COMMAND readlink ${library} OUTPUT_VARIABLE link)

      message(STATUS "${library}")
      if ("${link}" STREQUAL "")
        # Copy original files and framework folders
        if(IS_DIRECTORY ${library})
          install(DIRECTORY ${library} DESTINATION ${installLibFolder})
        else()
          install(PROGRAMS ${library} DESTINATION ${installLibFolder})
        endif()

      else()
        # Loop through possible chains of namelinks (i.e. lib.so -> lib.so.3.5 -> lib.so.3.5.1)
        while (NOT "${link}" STREQUAL "")
          # Recreate symlinks
          string(REGEX REPLACE "\n$" "" link "${link}") # Strip trailing newline
          #There are a few cases where directory information is contained inside the link variable.
          #The line below handles those cases (ie. /usr/lib64/libblas.so.3)
          execute_process(COMMAND basename ${link} OUTPUT_VARIABLE baselink)

          #install(CODE "EXECUTE_PROCESS(COMMAND ln -fs ${baselink} ${installLibFolder}/${relPath})")
          install(CODE "EXECUTE_PROCESS(COMMAND ln -fs ${librarypath}/${baselink} ${installLibFolder}/${baselink} )")
          #message("librarypath= ${librarypath}")
          #message ("baselink=${baselink}")
          #message("installlibFolder/relPath = ${installLibFolder} / ${relPath}")
          if (EXISTS "${librarypath}/${baselink}")
            install(PROGRAMS "${librarypath}/${baselink}" DESTINATION ${installLibFolder})
          endif()
          # Set next iteration of possible symlinks
          set(library "${librarypath}/${baselink}")
          file(RELATIVE_PATH relPath "${thirdPartyDir}/lib" ${library})
          execute_process(COMMAND readlink ${library} OUTPUT_VARIABLE link)
        endwhile()
      endif()
    endif()
  endforeach()

  # Copy over QT Frameworks
  if(APPLE)
    # execute_process(COMMAND cp -Lr ${library} ${installLibFolder})
  endif(APPLE)
endfunction()



# Plugin portion of the installation
function(install_third_party_plugins)

  # Where all the plugin files will go
  set(installPluginFolder "${CMAKE_INSTALL_PREFIX}/3rdParty/plugins")

  # Copy all of the plugin files
   foreach(plugin ${THIRDPARTYPLUGINS})
    file(RELATIVE_PATH relPath "${PLUGIN_DIR}" ${plugin})
    get_filename_component(relPath ${relPath} DIRECTORY) # Strip filename
    install(PROGRAMS ${plugin} DESTINATION ${installPluginFolder}/${relPath})
  endforeach()

endfunction()

# License portion of the installation
function(install_third_party_license)
  # Specify top level directories
  if(APPLE)
    set(LIC_DIR "/opt/usgs/v007/3rdParty/license")
  else()
    set(LIC_DIR "/usgs/pkgs/local/v007/license")
  endif()
  if(NOT EXISTS ${CMAKE_INSTALL_PREFIX}/3rdParty)
    install(CODE "execute_process(COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX}/3rdParty/)")
  endif()
  install(CODE "execute_process(COMMAND cp -r ${LIC_DIR} ${CMAKE_INSTALL_PREFIX}/3rdParty/license)")

endfunction()


# Install all third party libraries and plugins
function(install_third_party)

  # The files are available pre-build but are not copied until make-install is called.
  message("Setting up 3rd party lib installation...")
  install_third_party_libs()

  message("Setting up 3rd party plugin installation...")
  install_third_party_plugins()

  message("Obtaining licenses...")
  install_third_party_license()

  # Finish miscellaneous file installation
  install(FILES "${CMAKE_SOURCE_DIR}/3rdParty/lib/README"
          DESTINATION ${CMAKE_INSTALL_PREFIX}/3rdParty/lib)

endfunction()
