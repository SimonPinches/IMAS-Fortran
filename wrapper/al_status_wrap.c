/*
 * C wrappers around the al_* functions of the lowlevel C API (al_lowlevel.h)
 * that return an al_status_t struct by value.
 *
 * Some Fortran compilers cannot call BIND(C) functions returning a derived
 * type by value on every platform (e.g. flang on x86_64 Windows: "not yet
 * implemented: returning BIND(C) derived type for this target"). These
 * wrappers store the returned status in thread-local storage and return a
 * pointer to it instead, which the Fortran interface (al_low_level_wrap.f90)
 * converts with fstatus(). The pointer stays valid until the next wrapped
 * call on the same thread.
 */

#include "al_lowlevel.h"

#if defined(_MSC_VER)
#  define AL_THREAD_LOCAL __declspec(thread)
#else
#  define AL_THREAD_LOCAL _Thread_local
#endif

static AL_THREAD_LOCAL al_status_t al_fortran_status;

/* Define al_fortran_<name>(params) calling al_<name>(args) */
#define AL_STATUS_WRAP(name, params, args)              \
  const al_status_t *al_fortran_##name params           \
  {                                                     \
    al_fortran_status = al_##name args;                 \
    return &al_fortran_status;                          \
  }

AL_STATUS_WRAP(context_info,
               (int ctx, char **info),
               (ctx, info))
AL_STATUS_WRAP(get_backendID,
               (int ctx, int *beid),
               (ctx, beid))
AL_STATUS_WRAP(build_uri_from_legacy_parameters,
               (const int backendID, const int pulse, const int run,
                const char *user, const char *tokamak, const char *version,
                const char *options, char **uri),
               (backendID, pulse, run, user, tokamak, version, options, uri))
AL_STATUS_WRAP(begin_dataentry_action,
               (const char *uri, int mode, int *dectxID),
               (uri, mode, dectxID))
AL_STATUS_WRAP(close_pulse,
               (int pulseCtx, int mode),
               (pulseCtx, mode))
AL_STATUS_WRAP(begin_global_action,
               (int pctxID, const char *dataobjectname, const char *datapath,
                int rwmode, int *octxID),
               (pctxID, dataobjectname, datapath, rwmode, octxID))
AL_STATUS_WRAP(begin_slice_action,
               (int pctxID, const char *dataobjectname, int rwmode, double time,
                int interpmode, int *octxID),
               (pctxID, dataobjectname, rwmode, time, interpmode, octxID))
AL_STATUS_WRAP(begin_timerange_action,
               (int pctxID, const char *dataobjectname, int rwmode, double tmin,
                double tmax, const double *dtime_buffer, const int *dtime_shape,
                int interpmode, int *octxID),
               (pctxID, dataobjectname, rwmode, tmin, tmax, dtime_buffer,
                dtime_shape, interpmode, octxID))
AL_STATUS_WRAP(end_action,
               (int ctxID),
               (ctxID))
AL_STATUS_WRAP(delete_data,
               (int ctx, const char *path),
               (ctx, path))
AL_STATUS_WRAP(iterate_over_arraystruct,
               (int aosctx, int step),
               (aosctx, step))
AL_STATUS_WRAP(read_data,
               (int ctxID, const char *field, const char *timebase, void **data,
                int datatype, int dim, int *size),
               (ctxID, field, timebase, data, datatype, dim, size))
AL_STATUS_WRAP(write_data,
               (int ctxID, const char *field, const char *timebase, void *data,
                int datatype, int dim, int *size),
               (ctxID, field, timebase, data, datatype, dim, size))
AL_STATUS_WRAP(begin_arraystruct_action,
               (int ctxID, const char *path, const char *timebase, int *size,
                int *actxID),
               (ctxID, path, timebase, size, actxID))
AL_STATUS_WRAP(register_plugin,
               (const char *plugin_name),
               (plugin_name))
AL_STATUS_WRAP(unregister_plugin,
               (const char *plugin_name),
               (plugin_name))
AL_STATUS_WRAP(bind_plugin,
               (const char *fieldPath, const char *pluginName),
               (fieldPath, pluginName))
AL_STATUS_WRAP(unbind_plugin,
               (const char *fieldPath, const char *pluginName),
               (fieldPath, pluginName))
AL_STATUS_WRAP(bind_readback_plugins,
               (int ctxid),
               (ctxid))
AL_STATUS_WRAP(unbind_readback_plugins,
               (int ctxID),
               (ctxID))
AL_STATUS_WRAP(write_plugins_metadata,
               (int ctxid),
               (ctxid))
AL_STATUS_WRAP(setvalue_int_scalar_parameter_plugin,
               (const char *parameter_name, int parameter_value,
                const char *pluginName),
               (parameter_name, parameter_value, pluginName))
AL_STATUS_WRAP(setvalue_double_scalar_parameter_plugin,
               (const char *parameter_name, double parameter_value,
                const char *pluginName),
               (parameter_name, parameter_value, pluginName))
AL_STATUS_WRAP(setvalue_parameter_plugin,
               (const char *parameter_name, int datatype, int dim, int *size,
                void *data, const char *pluginName),
               (parameter_name, datatype, dim, size, data, pluginName))
AL_STATUS_WRAP(get_occurrences,
               (int pctxID, const char *ids_name, int **occurrences_list,
                int *size),
               (pctxID, ids_name, occurrences_list, size))
