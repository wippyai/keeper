import { describe, expect, it, vi } from 'vitest'
import {
  installHubDependency,
  planHubInstall,
  type HubInstallPlanResponse,
  type HubRequirement,
  type InstallPayload,
} from '../hub'

describe('hub API', () => {
  it('sends dependency requirement parameters during install', async () => {
    const api = { post: vi.fn().mockResolvedValue({ data: { success: true } }) } as any
    const payload: InstallPayload = {
      component: 'wippy/dummy',
      version: '0.1.2',
      run_migrations: true,
      migration_policy: 'up',
      parameters: [{ name: 'wippy.dummy:router', value: 'app:api.public' }],
    }

    await expect(installHubDependency(api, payload)).resolves.toEqual({ success: true })
    expect(api.post).toHaveBeenCalledWith('/api/v1/keeper/hub/dependencies/install', payload)
  })

  it('requests an install plan before runtime install', async () => {
    const plan: HubInstallPlanResponse = {
      success: true,
      dependency: { id: 'hub.dep:wippy_dummy', component: 'wippy/dummy', version: '0.1.2' },
      graph: [
        { module: 'wippy/dummy', namespace: 'wippy.dummy', version: '0.1.2', direct: true },
        { module: 'wippy/bootloader', namespace: 'wippy.bootloader', version: '1.0.0', direct: false, parent: 'wippy/dummy' },
      ],
      module_count: 2,
      requirements: [{
        name: 'env_storage',
        short_name: 'env_storage',
        parameter_name: 'wippy.bootloader:env_storage',
        full_id: 'wippy.bootloader:env_storage',
        module: 'wippy/bootloader',
        namespace: 'wippy.bootloader',
        required: true,
        missing: false,
        value: 'app.env:store',
        value_source: 'suggested',
        transitive: true,
      }],
      requirement_count: 1,
      missing_requirements: [],
      parameter_values: { 'wippy.bootloader:env_storage': 'app.env:store' },
      recommended_parameters: [{ name: 'wippy.bootloader:env_storage', value: 'app.env:store' }],
      migration_policy: 'up',
      install_payload: {
        component: 'wippy/dummy',
        version: '0.1.2',
        migration_policy: 'up',
        parameters: [{ name: 'wippy.bootloader:env_storage', value: 'app.env:store' }],
      },
    }
    const api = { post: vi.fn().mockResolvedValue({ data: plan }) } as any
    const payload: InstallPayload = {
      component: 'wippy/dummy',
      version: '0.1.2',
      parameters: [{ name: 'wippy.bootloader:env_storage', value: 'app.env:store' }],
    }

    await expect(planHubInstall(api, payload)).resolves.toEqual(plan)
    expect(api.post).toHaveBeenCalledWith('/api/v1/keeper/hub/dependencies/plan', payload)
  })

  it('models configuration requirements returned by hub versions', () => {
    const requirement: HubRequirement = {
      name: 'router',
      description: 'Router to register endpoints on',
      default: 'app:router',
      targets: [{ entry: 'wippy.dummy:ping', path: 'meta.router' }],
    }

    expect(requirement.name).toBe('router')
    expect(requirement.default).toBe('app:router')
    expect(requirement.targets?.[0].path).toBe('meta.router')
  })
})
