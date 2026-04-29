declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<Record<string, never>, Record<string, never>, unknown>
  export default component
}

declare module 'd3-force' {
  export interface SimulationNodeDatum {
    index?: number
    x?: number
    y?: number
    vx?: number
    vy?: number
    fx?: number | null
    fy?: number | null
  }

  export interface SimulationLinkDatum<NodeDatum extends SimulationNodeDatum> {
    source: string | NodeDatum
    target: string | NodeDatum
    index?: number
  }

  export interface Simulation<NodeDatum extends SimulationNodeDatum, LinkDatum extends SimulationLinkDatum<NodeDatum> | undefined = undefined> {
    force(name: string, force: unknown): this
    alphaDecay(value: number): this
    alphaTarget(value: number): this
    restart(): this
    stop(): this
    on(name: string, listener: (() => void) | null): this
  }

  export function forceSimulation<NodeDatum extends SimulationNodeDatum, LinkDatum extends SimulationLinkDatum<NodeDatum> = SimulationLinkDatum<NodeDatum>>(nodes?: NodeDatum[]): Simulation<NodeDatum, LinkDatum>
  export function forceLink<NodeDatum extends SimulationNodeDatum, LinkDatum extends SimulationLinkDatum<NodeDatum>>(links?: LinkDatum[]): {
    id(fn: (node: NodeDatum) => string): any
    distance(value: number): any
    strength(value: number): any
  }
  export function forceManyBody(): { strength(value: number): any }
  export function forceCenter(x?: number, y?: number): unknown
  export function forceCollide<NodeDatum extends SimulationNodeDatum>(): { radius(value: number): any }
}
