package=expat
$(package)_version=2.3.0
$(package)_download_path=https://github.com/libexpat/libexpat/releases/download/R_2_3_0
$(package)_file_name=$(package)-$($(package)_version).tar.bz2
$(package)_sha256_hash=f122a20eada303f904d5e0513326c5b821248f2d4d2afbf5c6f1339e511c0586

define $(package)_set_vars
$(package)_config_opts=--disable-shared --enable-static --with-pic
endef

define $(package)_config_cmds
  $($(package)_autoconf)
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef
