package=bdb
$(package)_version=4.8.30
$(package)_download_path=http://download.oracle.com/berkeley-db
$(package)_file_name=db-$($(package)_version).NC.tar.gz
$(package)_sha256_hash=12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef
$(package)_build_subdir=build_unix

define $(package)_set_vars
$(package)_config_opts=--disable-shared --enable-cxx --disable-replication
$(package)_config_opts_mingw32=--enable-mingw
$(package)_config_opts_linux=--with-pic
$(package)_config_opts_aarch64_linux=--with-pic
$(package)_cxxflags=-std=c++11
endef

define $(package)_preprocess_cmds
  sed -i.old 's/__atomic_compare_exchange/__atomic_compare_exchange_db/' dbinc/atomic.h && \
  sed -i.old 's/atomic_init/atomic_init_db/' dbinc/atomic.h mp/mp_region.c mp/mp_mvcc.c mp/mp_fget.c mutex/mut_method.c mutex/mut_tas.c && \
  if echo "$(host)" | grep -q "aarch64"; then \
    echo "Updating config files for ARM64 support..." && \
    (curl -sL -o dist/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' 2>/dev/null || \
     wget -q -O dist/config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' 2>/dev/null || \
     cp /usr/share/misc/config.guess dist/config.guess 2>/dev/null || \
     (echo "ERROR: Cannot update config.guess for ARM64 support" >&2 && false)) && \
    (curl -sL -o dist/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' 2>/dev/null || \
     wget -q -O dist/config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' 2>/dev/null || \
     cp /usr/share/misc/config.sub dist/config.sub 2>/dev/null || \
     (echo "ERROR: Cannot update config.sub for ARM64 support" >&2 && false)) && \
    chmod +x dist/config.guess dist/config.sub; \
  fi
endef

define $(package)_config_cmds
  ../dist/$($(package)_autoconf)
endef

define $(package)_build_cmds
  $(MAKE) libdb_cxx-4.8.a libdb-4.8.a
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install_lib install_include
endef
