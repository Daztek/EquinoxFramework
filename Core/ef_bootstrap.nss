#include "ef_c_annotations"
#include "ef_c_core"
#include "ef_c_log"
#include "ef_c_mediator"
#include "ef_c_profiler"

void Init()
{
    Log_Init();
    Profiler_Init();
    Mediator_Init();
    Annotations_Init();
    Core_Init();
}
