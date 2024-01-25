function status = CheckDesign(cfg)
logger = getLogger();
status = false;

disp(cfg)


%% perform all checks

logger.assert(isstruct(cfg), '`cfg` must be a struct')

logger.assert(isfield(cfg, 'TR') && isnumeric(cfg.TR) && isscalar(cfg.TR), ...
    'required field .TR=<numeric><scalar>')

logger.assert(isfield(cfg, 'contrast') && isnumeric(cfg.contrast) && isscalar(cfg.contrast), ...
    'required field .contrast=<numeric><scalar>')
logger.assert(cfg.contrast>=0 && cfg.contrast<=1, ...
    '.contrast must be from 0 to 1')

logger.assert(isfield(cfg, 'frequency') && isnumeric(cfg.frequency) && isscalar(cfg.frequency), ...
    'required field .frequency=<numeric><scalar>')
logger.assert(cfg.frequency>=0, ...
    '.frequency must be positive or null')

logger.assert(isfield(cfg, 'nSquareWidth') && isnumeric(cfg.nSquareWidth) && isscalar(cfg.nSquareWidth) && round(cfg.nSquareWidth)==cfg.nSquareWidth, ...
    'required field .nSquareWidth=<numeric><scalar><integer>')
logger.assert(cfg.nSquareWidth>=0, ...
    '.nSquareWidth must be a positive integer')

logger.assert(isfield(cfg, 'onset') && isnumeric(cfg.onset) && isvector(cfg.onset), ...
    'required field .onset=<numeric><vector>')


%% ok ? good to go

logger.log('design duration = %d volumes = %g seconds', length(cfg.onset), cfg.TR*length(cfg.onset))
logger.ok('config `%s` ok', cfg.name)
status = true;


end % fcn
