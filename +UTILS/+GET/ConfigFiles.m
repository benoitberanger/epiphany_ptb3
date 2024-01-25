function list = ConfigFiles()
logger = getLogger();
configdir = UTILS.GET.ConfigDir();
logger.log('config dir = %s', configdir)

dir_content = dir(fullfile(configdir, '*.m'));
list = {dir_content.name};
list = regexprep(list, '\.m$',''); % delete extension
end % fcn
