local consts = {
    PROCESS_NAMES = {
        LOGGER = "keeper.debug.logger.service",
    },

    PROCESS_HOST = "keeper.gov:processes",

    TOPICS = {
        COMMANDS = "logger.commands",
        RESPONSE = "logger.response",
    },

    OPERATIONS = {
        GET_LOGS = "get_logs",
        COMPOSITION = "composition",
        GET_STATS = "get_stats",
        GET_COUNTERS = "get_counters",
        CLEAR = "clear",
        CONFIGURE = "configure",
    },

    LOG_SYSTEM = "logs",
    LOG_ENTRY_KIND = "logs.entry",

    DEFAULT_BUFFER_SIZE = 50000,

    ERRORS = {
        INVALID_OPERATION = "Invalid operation",
        INVALID_PARAMS = "Invalid parameters",
        FILTER_COMPILE_FAILED = "Filter compilation failed",
    },
}

return table.freeze(consts)