#include "ef_c_core"
#include "ef_c_log"
#include "ef_c_messagebus"
#include "ef_c_profiler"
#include "ef_c_registry"

void Init()
{
    MessageBus_Init();
    Log_Init();
    Profiler_Init();
    Registry_Init();
    Core_Init();
}
