import{inject as Wt,ref as M,onUnmounted as Yt,computed as tt,useId as Pe,mergeProps as K,openBlock as b,createElementBlock as v,createElementVNode as u,renderSlot as ht,createTextVNode as A,toDisplayString as y,resolveComponent as Xt,resolveDirective as Ce,withDirectives as Te,createBlock as lt,resolveDynamicComponent as Oe,withCtx as it,createCommentVNode as V,normalizeClass as Z,defineComponent as bt,createVNode as S,unref as f,normalizeStyle as F,Fragment as X,renderList as et,withModifiers as Ht,onMounted as Ae,watch as Qt}from"vue";import{A as je,H as Ie,W as Ee,m as Nt,a as ft,C as pe,s as Dt,g as ut,F as be,N as dt,S as Q,B as W,c as ge,z as Le,b as Be,l as At,n as Ne,i as Zt,P as Ct,Q as De,d as It,T as Jt,R as te,v as Ve,e as ze,K as Me,f as Re,U as Ue}from"../app.js";import{Icon as I}from"@iconify/vue";import"vue-router";import"@wippy-fe/proxy";function yt(...t){if(t){let e=[];for(let n=0;n<t.length;n++){let r=t[n];if(!r)continue;let o=typeof r;if(o==="string"||o==="number")e.push(r);else if(o==="object"){let a=Array.isArray(r)?[yt(...r)]:Object.entries(r).map(([l,s])=>s?l:void 0);e=a.length?e.concat(a.filter(l=>!!l)):e}}return e.join(" ").trim()}}var Tt={};function We(t="pui_id_"){return Object.hasOwn(Tt,t)||(Tt[t]=0),Tt[t]++,`${t}${Tt[t]}`}function He(){const t=Wt(Ie);if(!t)throw new Error("HostApi not provided");return t}function Fe(){const t=Wt(je);if(!t)throw new Error("ProxyApiInstance not provided");return t}function Ge(){const t=Wt(Ee);if(!t)throw new Error("WIPPY_INSTANCE not provided");return t}function Vt(t){return typeof t=="object"&&t!==null}function ee(t){return t instanceof Error?t.message:String(t)}function Ke(t){return Vt(t)&&typeof t.error=="string"?t.error:"task failed"}function qe(t){return Vt(t)?Vt(t.data)?t.data:t:{}}function Et(){return"req-"+Date.now().toString(36)+"-"+Math.random().toString(36).slice(2,8)}function ne(t){const e={all:t.length,pending:0,ready:0,hidden:0,suspect:0,pushable_ready:0,blocked_ready:0};for(const n of t)n.decision==="pending"?e.pending+=1:n.decision==="approved"?(e.ready+=1,n.pushable?e.pushable_ready=(e.pushable_ready||0)+1:e.blocked_ready=(e.blocked_ready||0)+1):(n.decision==="skipped"||n.decision==="split"||n.decision==="pushed")&&(e.hidden+=1),(n.importance==="suspect"||n.decision==="orphan")&&(e.suspect+=1);return e}function Ye(t,e){const n=M(null),r=M(!1),o=M(!1),a=M(!1),l=M(null),s=M(null),i=18e4,d=new Map;function c(w){return new Promise((k,C)=>{const O=setTimeout(()=>{d.delete(w),C(new Error("event timeout — request_id "+w+" never arrived"))},i);d.set(w,{resolve:D=>k(D),reject:C,timer:O})})}function p(w,k,C){const O=d.get(w);O&&(clearTimeout(O.timer),d.delete(w),k?O.resolve(C):O.reject(new Error(Ke(C))))}let g=null;e&&(g=e.on("keeper.git",w=>{const k=qe(w),C=k.event;if(typeof C!="string")return;if(C==="git.rebuild.finished"&&k.snapshot)n.value={...k.snapshot,in_progress:!1};else if(C==="git.cluster.decision_changed"&&n.value){const D=n.value.clusters.find(Y=>Y.id===k.cluster_id);D&&k.decision&&(D.decision=k.decision),n.value.counts=ne(n.value.clusters)}else C==="git.index.stale"&&n.value&&(n.value.stale=!0);const O=k.request_id;O&&(C.endsWith(".finished")||C.endsWith(".failed"))&&p(O,C.endsWith(".finished"),k)})),Yt(()=>{g?.()});async function x(){r.value=!0,l.value=null;try{const{data:w}=await t.get("/api/v1/keeper/git/clusters");if(!w.success){l.value=w.error||"failed";return}n.value=w.snapshot}catch(w){l.value=ee(w)}finally{r.value=!1}}async function _(w={}){o.value=!0,l.value=null;try{const k=Et(),C={...w,request_id:k},{data:O}=await t.post("/api/v1/keeper/git/rebuild",C);if(!O.success){l.value=O.error||"rebuild failed";return}if(n.value=O.snapshot,O.snapshot?.in_progress&&e){const D=await c(k);D?.snapshot&&(n.value={...D.snapshot,in_progress:!1})}}catch(k){l.value=ee(k)}finally{o.value=!1}}async function B(w){const{data:k}=await t.get(`/api/v1/keeper/git/clusters/${w}`);if(!k.success)throw new Error(k.error||"cluster not found");return s.value=k.cluster,k.cluster}async function L(w,k){const{data:C}=await t.patch(`/api/v1/keeper/git/clusters/${w}/decision`,{decision:k});if(!C.success)throw new Error(C.error||"set_decision failed");if(n.value){const O=n.value.clusters.find(D=>D.id===w);O&&(O.decision=k),n.value.counts=ne(n.value.clusters)}s.value&&s.value.id===w&&(s.value.decision=k)}async function N(w,k,C){const{data:O}=await t.patch(`/api/v1/keeper/git/clusters/${w}/recommendations/${k}`,{state:C});if(!O.success)throw new Error(O.error||"update_recommendation failed");if(s.value&&s.value.id===w){const D=s.value.recommendations.find(Y=>Y.id===k);D&&(D.state=C)}await x()}async function R(w,k={}){const C=Et(),{data:O}=await t.post(`/api/v1/keeper/git/clusters/${w}/suggest-split`,{...k,request_id:C});if(!O.success)throw new Error(O.error||"suggest_split failed");if(O.mode!=="ai"||O.groups)return O;if(!e)throw new Error("AI suggest requires a relay subscriber");const D=await c(C);return{...O,...D}}async function z(w,k){const{data:C}=await t.post(`/api/v1/keeper/git/clusters/${w}/split`,{groups:k});if(!C.success)throw new Error(C.error||"split failed");return n.value=C.snapshot,C.snapshot}async function m(w,k,C=!1){const O=Et(),{data:D}=await t.post(`/api/v1/keeper/git/clusters/${w}/recommendations/${k}/explain`,{force:C,request_id:O});if(!D.success)throw new Error(D.error||"explain failed");if(D.cached||D.text){if(s.value&&s.value.id===w){const ot=s.value.recommendations.find(pt=>pt.id===k);ot&&(ot.detail=D.text)}return D}if(!e)throw new Error("Explain requires a relay subscriber");const Y=await c(O);if(s.value&&s.value.id===w){const ot=s.value.recommendations.find(pt=>pt.id===k);ot&&(ot.detail=Y.text)}return Y}async function j(w){const{data:k}=await t.get("/api/v1/keeper/git/diff",{params:{path:w}});if(!k.success)throw new Error(k.error||"diff failed");return{path:k.path,diff_text:k.diff_text||"",hunks:k.hunks||[],exit_code:k.exit_code}}async function q(w,k){a.value=!0;try{const{data:C}=await t.post("/api/v1/keeper/git/push",{cluster_ids:w,message:k});if(!C.success)throw new Error(C.error||"push failed");return await x(),C}finally{a.value=!1}}const nt=tt(()=>n.value?.counts.ready||0),gt=tt(()=>n.value?.stale||!1);return Yt(()=>{d.forEach(w=>clearTimeout(w.timer)),d.clear()}),{snapshot:n,loading:r,rebuilding:o,pushing:a,error:l,detail:s,readyCount:nt,stale:gt,refresh:x,rebuild:_,loadCluster:B,setDecision:L,updateRecommendation:N,explainRecommendation:m,fetchDiff:j,suggestSplit:R,splitCluster:z,pushApproved:q}}const Ot={critical:{dot:"var(--p-danger-500)",word:"Important"},high:{dot:"var(--p-warn-500)",word:"Worth attention"},normal:{dot:"var(--p-info-500)",word:"Routine"},cleanup:{dot:"var(--p-text-muted-color)",word:"Cleanup"},suspect:{dot:"var(--p-text-muted-color)",word:"Suspect"}},at={ready:{color:"var(--p-success-500)",bg:"color-mix(in srgb, var(--p-success-500) 7%, transparent)",border:"color-mix(in srgb, var(--p-success-500) 20%, transparent)",icon:"tabler:circle-check",phrase:"Looks ready"},closer_look:{color:"var(--p-warn-500)",bg:"color-mix(in srgb, var(--p-warn-500) 7%, transparent)",border:"color-mix(in srgb, var(--p-warn-500) 20%, transparent)",icon:"tabler:zoom-question",phrase:"Closer look"},do_not_push:{color:"var(--p-danger-500)",bg:"color-mix(in srgb, var(--p-danger-500) 7%, transparent)",border:"color-mix(in srgb, var(--p-danger-500) 20%, transparent)",icon:"tabler:hand-stop",phrase:"Don't push yet"}},Lt={info:{color:"var(--p-text-muted-color)",icon:"tabler:info-circle",bg:"transparent",label:"fyi"},warn:{color:"var(--p-warn-500)",icon:"tabler:alert-triangle",bg:"color-mix(in srgb, var(--p-warn-500) 10%, transparent)",label:"warn"},block:{color:"var(--p-danger-500)",icon:"tabler:hand-stop",bg:"color-mix(in srgb, var(--p-danger-500) 10%, transparent)",label:"block"}},Bt={open:{color:"var(--p-warn-500)",bg:"color-mix(in srgb, var(--p-warn-500) 13%, transparent)",label:"open",icon:"tabler:alert-circle"},acknowledged:{color:"var(--p-info-500)",bg:"color-mix(in srgb, var(--p-info-500) 13%, transparent)",label:"acknowledged",icon:"tabler:eye-check"},fixed:{color:"var(--p-success-500)",bg:"color-mix(in srgb, var(--p-success-500) 13%, transparent)",label:"fixed",icon:"tabler:check"},split:{color:"var(--p-text-muted-color)",bg:"color-mix(in srgb, var(--p-text-muted-color) 13%, transparent)",label:"split off",icon:"tabler:arrow-split"}};function Ft(t){return t+" change"+(t===1?"":"s")}function rt(t){return t instanceof Error?t.message:String(t)}var ct={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(e){return this._loadedStyleNames.has(e)},setLoadedStyleName:function(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName:function(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function Xe(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",e=Pe();return"".concat(t).concat(e.replace("v-","").replaceAll("-","_"))}var oe=W.extend({name:"common"});function xt(t){"@babel/helpers - typeof";return xt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},xt(t)}function Qe(t){return he(t)||Ze(t)||ve(t)||fe()}function Ze(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function vt(t,e){return he(t)||Je(t,e)||ve(t,e)||fe()}function fe(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ve(t,e){if(t){if(typeof t=="string")return zt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?zt(t,e):void 0}}function zt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function Je(t,e){var n=t==null?null:typeof Symbol<"u"&&t[Symbol.iterator]||t["@@iterator"];if(n!=null){var r,o,a,l,s=[],i=!0,d=!1;try{if(a=(n=n.call(t)).next,e===0){if(Object(n)!==n)return;i=!1}else for(;!(i=(r=a.call(n)).done)&&(s.push(r.value),s.length!==e);i=!0);}catch(c){d=!0,o=c}finally{try{if(!i&&n.return!=null&&(l=n.return(),Object(l)!==l))return}finally{if(d)throw o}}return s}}function he(t){if(Array.isArray(t))return t}function re(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter(function(o){return Object.getOwnPropertyDescriptor(t,o).enumerable})),n.push.apply(n,r)}return n}function T(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?re(Object(n),!0).forEach(function(r){mt(t,r,n[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):re(Object(n)).forEach(function(r){Object.defineProperty(t,r,Object.getOwnPropertyDescriptor(n,r))})}return t}function mt(t,e,n){return(e=tn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function tn(t){var e=en(t,"string");return xt(e)=="symbol"?e:e+""}function en(t,e){if(xt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(xt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Gt={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(e){dt.off("theme:change",this._loadCoreStyles),e||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(e,n){var r=this;dt.off("theme:change",this._themeScopedListener),e?(this._loadScopedThemeStyles(e),this._themeScopedListener=function(){return r._loadScopedThemeStyles(e)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var e,n,r,o,a,l,s,i,d,c,p,g=(e=this.pt)===null||e===void 0?void 0:e._usept,x=g?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,_=g?(r=this.pt)===null||r===void 0||(r=r.value)===null||r===void 0?void 0:r[this.$.type.name]:this.pt;(o=_||x)===null||o===void 0||(o=o.hooks)===null||o===void 0||(a=o.onBeforeCreate)===null||a===void 0||a.call(o);var B=(l=this.$primevueConfig)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l._usept,L=B?(s=this.$primevue)===null||s===void 0||(s=s.config)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s.originalValue:void 0,N=B?(i=this.$primevue)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.pt)===null||i===void 0?void 0:i.value:(d=this.$primevue)===null||d===void 0||(d=d.config)===null||d===void 0?void 0:d.pt;(c=N||L)===null||c===void 0||(c=c[this.$.type.name])===null||c===void 0||(c=c.hooks)===null||c===void 0||(p=c.onBeforeCreate)===null||p===void 0||p.call(c),this.$attrSelector=Xe(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var e;this.rootEl=Le(Be(this.$el)?this.$el:(e=this.$el)===null||e===void 0?void 0:e.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=T({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(e){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(e)),r=this._useDefaultPT(this._getOptionValue,"hooks.".concat(e));n?.(),r?.()}},_mergeProps:function(e){for(var n=arguments.length,r=new Array(n>1?n-1:0),o=1;o<n;o++)r[o-1]=arguments[o];return ge(e)?e.apply(void 0,r):K.apply(void 0,r)},_load:function(){ct.isStyleNameLoaded("base")||(W.loadCSS(this.$styleOptions),this._loadGlobalStyles(),ct.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var e,n;!ct.isStyleNameLoaded((e=this.$style)===null||e===void 0?void 0:e.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(oe.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),ct.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var e=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);Dt(e)&&W.load(e,T({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var e,n;if(!(this.isUnstyled||this.$theme==="none")){if(!Q.isStyleNameLoaded("common")){var r,o,a=((r=this.$style)===null||r===void 0||(o=r.getCommonTheme)===null||o===void 0?void 0:o.call(r))||{},l=a.primitive,s=a.semantic,i=a.global,d=a.style;W.load(l?.css,T({name:"primitive-variables"},this.$styleOptions)),W.load(s?.css,T({name:"semantic-variables"},this.$styleOptions)),W.load(i?.css,T({name:"global-variables"},this.$styleOptions)),W.loadStyle(T({name:"global-style"},this.$styleOptions),d),Q.setLoadedStyleName("common")}if(!Q.isStyleNameLoaded((e=this.$style)===null||e===void 0?void 0:e.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var c,p,g,x,_=((c=this.$style)===null||c===void 0||(p=c.getComponentTheme)===null||p===void 0?void 0:p.call(c))||{},B=_.css,L=_.style;(g=this.$style)===null||g===void 0||g.load(B,T({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(x=this.$style)===null||x===void 0||x.loadStyle(T({name:"".concat(this.$style.name,"-style")},this.$styleOptions),L),Q.setLoadedStyleName(this.$style.name)}if(!Q.isStyleNameLoaded("layer-order")){var N,R,z=(N=this.$style)===null||N===void 0||(R=N.getLayerOrderThemeCSS)===null||R===void 0?void 0:R.call(N);W.load(z,T({name:"layer-order",first:!0},this.$styleOptions)),Q.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(e){var n,r,o,a=((n=this.$style)===null||n===void 0||(r=n.getPresetTheme)===null||r===void 0?void 0:r.call(n,e,"[".concat(this.$attrSelector,"]")))||{},l=a.css,s=(o=this.$style)===null||o===void 0?void 0:o.load(l,T({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=s.el},_unloadScopedThemeStyles:function(){var e;(e=this.scopedStyleEl)===null||e===void 0||(e=e.value)===null||e===void 0||e.remove()},_themeChangeListener:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};ct.clearLoadedStyleNames(),dt.on("theme:change",e)},_removeThemeListeners:function(){dt.off("theme:change",this._loadCoreStyles),dt.off("theme:change",this._load),dt.off("theme:change",this._themeScopedListener)},_getHostInstance:function(e){return e?this.$options.hostName?e.$.type.name===this.$options.hostName?e:this._getHostInstance(e.$parentInstance):e.$parentInstance:void 0},_getPropValue:function(e){var n;return this[e]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[e])},_getOptionValue:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return be(e,n,r)},_getPTValue:function(){var e,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,l=/./g.test(r)&&!!o[r.split(".")[0]],s=this._getPropValue("ptOptions")||((e=this.$primevueConfig)===null||e===void 0?void 0:e.ptOptions)||{},i=s.mergeSections,d=i===void 0?!0:i,c=s.mergeProps,p=c===void 0?!1:c,g=a?l?this._useGlobalPT(this._getPTClassValue,r,o):this._useDefaultPT(this._getPTClassValue,r,o):void 0,x=l?void 0:this._getPTSelf(n,this._getPTClassValue,r,T(T({},o),{},{global:g||{}})),_=this._getPTDatasets(r);return d||!d&&x?p?this._mergeProps(p,g,x,_):T(T(T({},g),x),_):T(T({},x),_)},_getPTSelf:function(){for(var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,r=new Array(n>1?n-1:0),o=1;o<n;o++)r[o-1]=arguments[o];return K(this._usePT.apply(this,[this._getPT(e,this.$name)].concat(r)),this._usePT.apply(this,[this.$_attrsPT].concat(r)))},_getPTDatasets:function(){var e,n,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o="data-pc-",a=r==="root"&&Dt((e=this.pt)===null||e===void 0?void 0:e["data-pc-section"]);return r!=="transition"&&T(T({},r==="root"&&T(T(mt({},"".concat(o,"name"),ut(a?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),a&&mt({},"".concat(o,"extend"),ut(this.$.type.name))),{},mt({},"".concat(this.$attrSelector),""))),{},mt({},"".concat(o,"section"),ut(r)))},_getPTClassValue:function(){var e=this._getOptionValue.apply(this,arguments);return ft(e)||pe(e)?{class:e}:e},_getPT:function(e){var n=this,r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,a=function(s){var i,d=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,c=o?o(s):s,p=ut(r),g=ut(n.$name);return(i=d?p!==g?c?.[p]:void 0:c?.[p])!==null&&i!==void 0?i:c};return e!=null&&e.hasOwnProperty("_usept")?{_usept:e._usept,originalValue:a(e.originalValue),value:a(e.value)}:a(e,!0)},_usePT:function(e,n,r,o){var a=function(B){return n(B,r,o)};if(e!=null&&e.hasOwnProperty("_usept")){var l,s=e._usept||((l=this.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},i=s.mergeSections,d=i===void 0?!0:i,c=s.mergeProps,p=c===void 0?!1:c,g=a(e.originalValue),x=a(e.value);return g===void 0&&x===void 0?void 0:ft(x)?x:ft(g)?g:d||!d&&x?p?this._mergeProps(p,g,x):T(T({},g),x):x}return a(e)},_useGlobalPT:function(e,n,r){return this._usePT(this.globalPT,e,n,r)},_useDefaultPT:function(e,n,r){return this._usePT(this.defaultPT,e,n,r)},ptm:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,e,T(T({},this.$params),n))},ptmi:function(){var e,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=K(this.$_attrsWithoutPT,this.ptm(n,r));return o?.hasOwnProperty("id")&&((e=o.id)!==null&&e!==void 0||(o.id=this.$id)),o},ptmo:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(e,n,T({instance:this},r),!1)},cx:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,e,T(T({},this.$params),n))},sx:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var o=this._getOptionValue(this.$style.inlineStyles,e,T(T({},this.$params),r)),a=this._getOptionValue(oe.inlineStyles,e,T(T({},this.$params),r));return[a,o]}}},computed:{globalPT:function(){var e,n=this;return this._getPT((e=this.$primevueConfig)===null||e===void 0?void 0:e.pt,void 0,function(r){return Nt(r,{instance:n})})},defaultPT:function(){var e,n=this;return this._getPT((e=this.$primevueConfig)===null||e===void 0?void 0:e.pt,void 0,function(r){return n._getOptionValue(r,n.$name,T({},n.$params))||Nt(r,T({},n.$params))})},isUnstyled:function(){var e;return this.unstyled!==void 0?this.unstyled:(e=this.$primevueConfig)===null||e===void 0?void 0:e.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var e,n=Object.keys(((e=this.$.vnode)===null||e===void 0?void 0:e.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(r){var o=vt(r,1),a=o[0];return n?.includes(a)}))},$theme:function(){var e;return(e=this.$primevueConfig)===null||e===void 0?void 0:e.theme},$style:function(){return T(T({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var e;return{nonce:(e=this.$primevueConfig)===null||e===void 0||(e=e.csp)===null||e===void 0?void 0:e.nonce}},$primevueConfig:function(){var e;return(e=this.$primevue)===null||e===void 0?void 0:e.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var e=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:e,props:e?.$props,state:e?.$data,attrs:e?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(e){var n=vt(e,1),r=n[0];return r?.startsWith("pt:")}).reduce(function(e,n){var r=vt(n,2),o=r[0],a=r[1],l=o.split(":"),s=Qe(l),i=zt(s).slice(1);return i?.reduce(function(d,c,p,g){return!d[c]&&(d[c]=p===g.length-1?a:{}),d[c]},e),e},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(e){var n=vt(e,1),r=n[0];return!(r!=null&&r.startsWith("pt:"))}).reduce(function(e,n){var r=vt(n,2),o=r[0],a=r[1];return e[o]=a,e},{})}}},nn=`
.p-icon {
    display: inline-block;
    vertical-align: baseline;
    flex-shrink: 0;
}

.p-icon-spin {
    -webkit-animation: p-icon-spin 2s infinite linear;
    animation: p-icon-spin 2s infinite linear;
}

@-webkit-keyframes p-icon-spin {
    0% {
        -webkit-transform: rotate(0deg);
        transform: rotate(0deg);
    }
    100% {
        -webkit-transform: rotate(359deg);
        transform: rotate(359deg);
    }
}

@keyframes p-icon-spin {
    0% {
        -webkit-transform: rotate(0deg);
        transform: rotate(0deg);
    }
    100% {
        -webkit-transform: rotate(359deg);
        transform: rotate(359deg);
    }
}
`,on=W.extend({name:"baseicon",css:nn});function kt(t){"@babel/helpers - typeof";return kt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},kt(t)}function ae(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter(function(o){return Object.getOwnPropertyDescriptor(t,o).enumerable})),n.push.apply(n,r)}return n}function ie(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?ae(Object(n),!0).forEach(function(r){rn(t,r,n[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):ae(Object(n)).forEach(function(r){Object.defineProperty(t,r,Object.getOwnPropertyDescriptor(n,r))})}return t}function rn(t,e,n){return(e=an(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function an(t){var e=sn(t,"string");return kt(e)=="symbol"?e:e+""}function sn(t,e){if(kt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(kt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var ln={name:"BaseIcon",extends:Gt,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:on,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var e=At(this.label);return ie(ie({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:e?void 0:"img","aria-label":e?void 0:this.label,"aria-hidden":e})}}},me={name:"SpinnerIcon",extends:ln};function dn(t){return bn(t)||pn(t)||cn(t)||un()}function un(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function cn(t,e){if(t){if(typeof t=="string")return Mt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Mt(t,e):void 0}}function pn(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function bn(t){if(Array.isArray(t))return Mt(t)}function Mt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function gn(t,e,n,r,o,a){return b(),v("svg",K({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),dn(e[0]||(e[0]=[u("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}me.render=gn;var fn=`
    .p-badge {
        display: inline-flex;
        border-radius: dt('badge.border.radius');
        align-items: center;
        justify-content: center;
        padding: dt('badge.padding');
        background: dt('badge.primary.background');
        color: dt('badge.primary.color');
        font-size: dt('badge.font.size');
        font-weight: dt('badge.font.weight');
        min-width: dt('badge.min.width');
        height: dt('badge.height');
    }

    .p-badge-dot {
        width: dt('badge.dot.size');
        min-width: dt('badge.dot.size');
        height: dt('badge.dot.size');
        border-radius: 50%;
        padding: 0;
    }

    .p-badge-circle {
        padding: 0;
        border-radius: 50%;
    }

    .p-badge-secondary {
        background: dt('badge.secondary.background');
        color: dt('badge.secondary.color');
    }

    .p-badge-success {
        background: dt('badge.success.background');
        color: dt('badge.success.color');
    }

    .p-badge-info {
        background: dt('badge.info.background');
        color: dt('badge.info.color');
    }

    .p-badge-warn {
        background: dt('badge.warn.background');
        color: dt('badge.warn.color');
    }

    .p-badge-danger {
        background: dt('badge.danger.background');
        color: dt('badge.danger.color');
    }

    .p-badge-contrast {
        background: dt('badge.contrast.background');
        color: dt('badge.contrast.color');
    }

    .p-badge-sm {
        font-size: dt('badge.sm.font.size');
        min-width: dt('badge.sm.min.width');
        height: dt('badge.sm.height');
    }

    .p-badge-lg {
        font-size: dt('badge.lg.font.size');
        min-width: dt('badge.lg.min.width');
        height: dt('badge.lg.height');
    }

    .p-badge-xl {
        font-size: dt('badge.xl.font.size');
        min-width: dt('badge.xl.min.width');
        height: dt('badge.xl.height');
    }
`,vn={root:function(e){var n=e.props,r=e.instance;return["p-badge p-component",{"p-badge-circle":Dt(n.value)&&String(n.value).length===1,"p-badge-dot":At(n.value)&&!r.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},hn=W.extend({name:"badge",style:fn,classes:vn}),mn={name:"BaseBadge",extends:Gt,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:hn,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function $t(t){"@babel/helpers - typeof";return $t=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},$t(t)}function se(t,e,n){return(e=yn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function yn(t){var e=xn(t,"string");return $t(e)=="symbol"?e:e+""}function xn(t,e){if($t(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if($t(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var ye={name:"Badge",extends:mn,inheritAttrs:!1,computed:{dataP:function(){return yt(se(se({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},kn=["data-p"];function $n(t,e,n,r,o,a){return b(),v("span",K({class:t.cx("root"),"data-p":a.dataP},t.ptmi("root")),[ht(t.$slots,"default",{},function(){return[A(y(t.value),1)]})],16,kn)}ye.render=$n;function wt(t){"@babel/helpers - typeof";return wt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},wt(t)}function le(t,e){return Pn(t)||_n(t,e)||Sn(t,e)||wn()}function wn(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Sn(t,e){if(t){if(typeof t=="string")return de(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?de(t,e):void 0}}function de(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function _n(t,e){var n=t==null?null:typeof Symbol<"u"&&t[Symbol.iterator]||t["@@iterator"];if(n!=null){var r,o,a,l,s=[],i=!0,d=!1;try{if(a=(n=n.call(t)).next,e!==0)for(;!(i=(r=a.call(n)).done)&&(s.push(r.value),s.length!==e);i=!0);}catch(c){d=!0,o=c}finally{try{if(!i&&n.return!=null&&(l=n.return(),Object(l)!==l))return}finally{if(d)throw o}}return s}}function Pn(t){if(Array.isArray(t))return t}function ue(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter(function(o){return Object.getOwnPropertyDescriptor(t,o).enumerable})),n.push.apply(n,r)}return n}function E(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?ue(Object(n),!0).forEach(function(r){Rt(t,r,n[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):ue(Object(n)).forEach(function(r){Object.defineProperty(t,r,Object.getOwnPropertyDescriptor(n,r))})}return t}function Rt(t,e,n){return(e=Cn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Cn(t){var e=Tn(t,"string");return wt(e)=="symbol"?e:e+""}function Tn(t,e){if(wt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(wt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var P={_getMeta:function(){return[Zt(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],Nt(Zt(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(e,n){var r,o,a;return(r=(e==null||(o=e.instance)===null||o===void 0?void 0:o.$primevue)||(n==null||(a=n.ctx)===null||a===void 0||(a=a.appContext)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.globalProperties)===null||a===void 0?void 0:a.$primevue))===null||r===void 0?void 0:r.config},_getOptionValue:be,_getPTValue:function(){var e,n,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},a=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",l=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},s=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,i=function(){var R=P._getOptionValue.apply(P,arguments);return ft(R)||pe(R)?{class:R}:R},d=((e=r.binding)===null||e===void 0||(e=e.value)===null||e===void 0?void 0:e.ptOptions)||((n=r.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},c=d.mergeSections,p=c===void 0?!0:c,g=d.mergeProps,x=g===void 0?!1:g,_=s?P._useDefaultPT(r,r.defaultPT(),i,a,l):void 0,B=P._usePT(r,P._getPT(o,r.$name),i,a,E(E({},l),{},{global:_||{}})),L=P._getPTDatasets(r,a);return p||!p&&B?x?P._mergeProps(r,x,_,B,L):E(E(E({},_),B),L):E(E({},B),L)},_getPTDatasets:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r="data-pc-";return E(E({},n==="root"&&Rt({},"".concat(r,"name"),ut(e.$name))),{},Rt({},"".concat(r,"section"),ut(n)))},_getPT:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,o=function(l){var s,i=r?r(l):l,d=ut(n);return(s=i?.[d])!==null&&s!==void 0?s:i};return e&&Object.hasOwn(e,"_usept")?{_usept:e._usept,originalValue:o(e.originalValue),value:o(e.value)}:o(e)},_usePT:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,o=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0,l=function(L){return r(L,o,a)};if(n&&Object.hasOwn(n,"_usept")){var s,i=n._usept||((s=e.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},d=i.mergeSections,c=d===void 0?!0:d,p=i.mergeProps,g=p===void 0?!1:p,x=l(n.originalValue),_=l(n.value);return x===void 0&&_===void 0?void 0:ft(_)?_:ft(x)?x:c||!c&&_?g?P._mergeProps(e,g,x,_):E(E({},x),_):_}return l(n)},_useDefaultPT:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=arguments.length>2?arguments[2]:void 0,o=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0;return P._usePT(e,n,r,o,a)},_loadStyles:function(){var e,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,a=P._getConfig(r,o),l={nonce:a==null||(e=a.csp)===null||e===void 0?void 0:e.nonce};P._loadCoreStyles(n,l),P._loadThemeStyles(n,l),P._loadScopedThemeStyles(n,l),P._removeThemeListeners(n),n.$loadStyles=function(){return P._loadThemeStyles(n,l)},P._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var e,n,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0;if(!ct.isStyleNameLoaded((e=r.$style)===null||e===void 0?void 0:e.name)&&(n=r.$style)!==null&&n!==void 0&&n.name){var a;W.loadCSS(o),(a=r.$style)===null||a===void 0||a.loadCSS(o),ct.setLoadedStyleName(r.$style.name)}},_loadThemeStyles:function(){var e,n,r,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},a=arguments.length>1?arguments[1]:void 0;if(!(o!=null&&o.isUnstyled()||(o==null||(e=o.theme)===null||e===void 0?void 0:e.call(o))==="none")){if(!Q.isStyleNameLoaded("common")){var l,s,i=((l=o.$style)===null||l===void 0||(s=l.getCommonTheme)===null||s===void 0?void 0:s.call(l))||{},d=i.primitive,c=i.semantic,p=i.global,g=i.style;W.load(d?.css,E({name:"primitive-variables"},a)),W.load(c?.css,E({name:"semantic-variables"},a)),W.load(p?.css,E({name:"global-variables"},a)),W.loadStyle(E({name:"global-style"},a),g),Q.setLoadedStyleName("common")}if(!Q.isStyleNameLoaded((n=o.$style)===null||n===void 0?void 0:n.name)&&(r=o.$style)!==null&&r!==void 0&&r.name){var x,_,B,L,N=((x=o.$style)===null||x===void 0||(_=x.getDirectiveTheme)===null||_===void 0?void 0:_.call(x))||{},R=N.css,z=N.style;(B=o.$style)===null||B===void 0||B.load(R,E({name:"".concat(o.$style.name,"-variables")},a)),(L=o.$style)===null||L===void 0||L.loadStyle(E({name:"".concat(o.$style.name,"-style")},a),z),Q.setLoadedStyleName(o.$style.name)}if(!Q.isStyleNameLoaded("layer-order")){var m,j,q=(m=o.$style)===null||m===void 0||(j=m.getLayerOrderThemeCSS)===null||j===void 0?void 0:j.call(m);W.load(q,E({name:"layer-order",first:!0},a)),Q.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,r=e.preset();if(r&&e.$attrSelector){var o,a,l,s=((o=e.$style)===null||o===void 0||(a=o.getPresetTheme)===null||a===void 0?void 0:a.call(o,r,"[".concat(e.$attrSelector,"]")))||{},i=s.css,d=(l=e.$style)===null||l===void 0?void 0:l.load(i,E({name:"".concat(e.$attrSelector,"-").concat(e.$style.name)},n));e.scopedStyleEl=d.el}},_themeChangeListener:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};ct.clearLoadedStyleNames(),dt.on("theme:change",e)},_removeThemeListeners:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};dt.off("theme:change",e.$loadStyles),e.$loadStyles=void 0},_hook:function(e,n,r,o,a,l){var s,i,d="on".concat(Ne(n)),c=P._getConfig(o,a),p=r?.$instance,g=P._usePT(p,P._getPT(o==null||(s=o.value)===null||s===void 0?void 0:s.pt,e),P._getOptionValue,"hooks.".concat(d)),x=P._useDefaultPT(p,c==null||(i=c.pt)===null||i===void 0||(i=i.directives)===null||i===void 0?void 0:i[e],P._getOptionValue,"hooks.".concat(d)),_={el:r,binding:o,vnode:a,prevVnode:l};g?.(p,_),x?.(p,_)},_mergeProps:function(){for(var e=arguments.length>1?arguments[1]:void 0,n=arguments.length,r=new Array(n>2?n-2:0),o=2;o<n;o++)r[o-2]=arguments[o];return ge(e)?e.apply(void 0,r):K.apply(void 0,r)},_extend:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=function(s,i,d,c,p){var g,x,_,B;i._$instances=i._$instances||{};var L=P._getConfig(d,c),N=i._$instances[e]||{},R=At(N)?E(E({},n),n?.methods):{};i._$instances[e]=E(E({},N),{},{$name:e,$host:i,$binding:d,$modifiers:d?.modifiers,$value:d?.value,$el:N.$el||i||void 0,$style:E({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:L,$attrSelector:(g=i.$pd)===null||g===void 0||(g=g[e])===null||g===void 0?void 0:g.attrSelector,defaultPT:function(){return P._getPT(L?.pt,void 0,function(m){var j;return m==null||(j=m.directives)===null||j===void 0?void 0:j[e]})},isUnstyled:function(){var m,j;return((m=i._$instances[e])===null||m===void 0||(m=m.$binding)===null||m===void 0||(m=m.value)===null||m===void 0?void 0:m.unstyled)!==void 0?(j=i._$instances[e])===null||j===void 0||(j=j.$binding)===null||j===void 0||(j=j.value)===null||j===void 0?void 0:j.unstyled:L?.unstyled},theme:function(){var m;return(m=i._$instances[e])===null||m===void 0||(m=m.$primevueConfig)===null||m===void 0?void 0:m.theme},preset:function(){var m;return(m=i._$instances[e])===null||m===void 0||(m=m.$binding)===null||m===void 0||(m=m.value)===null||m===void 0?void 0:m.dt},ptm:function(){var m,j=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",q=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return P._getPTValue(i._$instances[e],(m=i._$instances[e])===null||m===void 0||(m=m.$binding)===null||m===void 0||(m=m.value)===null||m===void 0?void 0:m.pt,j,E({},q))},ptmo:function(){var m=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},j=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",q=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return P._getPTValue(i._$instances[e],m,j,q,!1)},cx:function(){var m,j,q=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",nt=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(m=i._$instances[e])!==null&&m!==void 0&&m.isUnstyled()?void 0:P._getOptionValue((j=i._$instances[e])===null||j===void 0||(j=j.$style)===null||j===void 0?void 0:j.classes,q,E({},nt))},sx:function(){var m,j=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",q=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,nt=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return q?P._getOptionValue((m=i._$instances[e])===null||m===void 0||(m=m.$style)===null||m===void 0?void 0:m.inlineStyles,j,E({},nt)):void 0}},R),i.$instance=i._$instances[e],(x=(_=i.$instance)[s])===null||x===void 0||x.call(_,i,d,c,p),i["$".concat(e)]=i.$instance,P._hook(e,s,i,d,c,p),i.$pd||(i.$pd={}),i.$pd[e]=E(E({},(B=i.$pd)===null||B===void 0?void 0:B[e]),{},{name:e,instance:i._$instances[e]})},o=function(s){var i,d,c,p=s._$instances[e],g=p?.watch,x=function(L){var N,R=L.newValue,z=L.oldValue;return g==null||(N=g.config)===null||N===void 0?void 0:N.call(p,R,z)},_=function(L){var N,R=L.newValue,z=L.oldValue;return g==null||(N=g["config.ripple"])===null||N===void 0?void 0:N.call(p,R,z)};p.$watchersCallback={config:x,"config.ripple":_},g==null||(i=g.config)===null||i===void 0||i.call(p,p?.$primevueConfig),Ct.on("config:change",x),g==null||(d=g["config.ripple"])===null||d===void 0||d.call(p,p==null||(c=p.$primevueConfig)===null||c===void 0?void 0:c.ripple),Ct.on("config:ripple:change",_)},a=function(s){var i=s._$instances[e].$watchersCallback;i&&(Ct.off("config:change",i.config),Ct.off("config:ripple:change",i["config.ripple"]),s._$instances[e].$watchersCallback=void 0)};return{created:function(s,i,d,c){s.$pd||(s.$pd={}),s.$pd[e]={name:e,attrSelector:We("pd")},r("created",s,i,d,c)},beforeMount:function(s,i,d,c){var p;P._loadStyles((p=s.$pd[e])===null||p===void 0?void 0:p.instance,i,d),r("beforeMount",s,i,d,c),o(s)},mounted:function(s,i,d,c){var p;P._loadStyles((p=s.$pd[e])===null||p===void 0?void 0:p.instance,i,d),r("mounted",s,i,d,c)},beforeUpdate:function(s,i,d,c){r("beforeUpdate",s,i,d,c)},updated:function(s,i,d,c){var p;P._loadStyles((p=s.$pd[e])===null||p===void 0?void 0:p.instance,i,d),r("updated",s,i,d,c)},beforeUnmount:function(s,i,d,c){var p;a(s),P._removeThemeListeners((p=s.$pd[e])===null||p===void 0?void 0:p.instance),r("beforeUnmount",s,i,d,c)},unmounted:function(s,i,d,c){var p;(p=s.$pd[e])===null||p===void 0||(p=p.instance)===null||p===void 0||(p=p.scopedStyleEl)===null||p===void 0||(p=p.value)===null||p===void 0||p.remove(),r("unmounted",s,i,d,c)}}},extend:function(){var e=P._getMeta.apply(P,arguments),n=le(e,2),r=n[0],o=n[1];return E({extend:function(){var l=P._getMeta.apply(P,arguments),s=le(l,2),i=s[0],d=s[1];return P.extend(i,E(E(E({},o),o?.methods),d))}},P._extend(r,o))}},On=`
    .p-ink {
        display: block;
        position: absolute;
        background: dt('ripple.background');
        border-radius: 100%;
        transform: scale(0);
        pointer-events: none;
    }

    .p-ink-active {
        animation: ripple 0.4s linear;
    }

    @keyframes ripple {
        100% {
            opacity: 0;
            transform: scale(2.5);
        }
    }
`,An={root:"p-ink"},jn=W.extend({name:"ripple-directive",style:On,classes:An}),In=P.extend({style:jn});function St(t){"@babel/helpers - typeof";return St=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},St(t)}function En(t){return Dn(t)||Nn(t)||Bn(t)||Ln()}function Ln(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Bn(t,e){if(t){if(typeof t=="string")return Ut(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Ut(t,e):void 0}}function Nn(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function Dn(t){if(Array.isArray(t))return Ut(t)}function Ut(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function ce(t,e,n){return(e=Vn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Vn(t){var e=zn(t,"string");return St(e)=="symbol"?e:e+""}function zn(t,e){if(St(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(St(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Mn=In.extend("ripple",{watch:{"config.ripple":function(e){e?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(e){this.remove(e)},timeout:void 0,methods:{bindEvents:function(e){e.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(e){e.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(e){var n=this.getInk(e);n||(n=Ue("span",ce(ce({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),e.appendChild(n),this.$el=n)},remove:function(e){var n=this.getInk(e);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(e),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(e){var n=this,r=e.currentTarget,o=this.getInk(r);if(!(!o||getComputedStyle(o,null).display==="none")){if(!this.isUnstyled()&&It(o,"p-ink-active"),o.setAttribute("data-p-ink-active","false"),!Jt(o)&&!te(o)){var a=Math.max(Ve(r),ze(r));o.style.height=a+"px",o.style.width=a+"px"}var l=Me(r),s=e.pageX-l.left+document.body.scrollTop-te(o)/2,i=e.pageY-l.top+document.body.scrollLeft-Jt(o)/2;o.style.top=i+"px",o.style.left=s+"px",!this.isUnstyled()&&Re(o,"p-ink-active"),o.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){o&&(!n.isUnstyled()&&It(o,"p-ink-active"),o.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(e){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&It(e.currentTarget,"p-ink-active"),e.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(e){return e&&e.children?En(e.children).find(function(n){return De(n,"data-pc-name")==="ripple"}):void 0}}}),Rn=`
    .p-button {
        display: inline-flex;
        cursor: pointer;
        user-select: none;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        position: relative;
        color: dt('button.primary.color');
        background: dt('button.primary.background');
        border: 1px solid dt('button.primary.border.color');
        padding: dt('button.padding.y') dt('button.padding.x');
        font-size: 1rem;
        font-family: inherit;
        font-feature-settings: inherit;
        transition:
            background dt('button.transition.duration'),
            color dt('button.transition.duration'),
            border-color dt('button.transition.duration'),
            outline-color dt('button.transition.duration'),
            box-shadow dt('button.transition.duration');
        border-radius: dt('button.border.radius');
        outline-color: transparent;
        gap: dt('button.gap');
    }

    .p-button:disabled {
        cursor: default;
    }

    .p-button-icon-right {
        order: 1;
    }

    .p-button-icon-right:dir(rtl) {
        order: -1;
    }

    .p-button:not(.p-button-vertical) .p-button-icon:not(.p-button-icon-right):dir(rtl) {
        order: 1;
    }

    .p-button-icon-bottom {
        order: 2;
    }

    .p-button-icon-only {
        width: dt('button.icon.only.width');
        padding-inline-start: 0;
        padding-inline-end: 0;
        gap: 0;
    }

    .p-button-icon-only.p-button-rounded {
        border-radius: 50%;
        height: dt('button.icon.only.width');
    }

    .p-button-icon-only .p-button-label {
        visibility: hidden;
        width: 0;
    }

    .p-button-icon-only::after {
        content: " ";
        visibility: hidden;
        width: 0;
    }

    .p-button-sm {
        font-size: dt('button.sm.font.size');
        padding: dt('button.sm.padding.y') dt('button.sm.padding.x');
    }

    .p-button-sm .p-button-icon {
        font-size: dt('button.sm.font.size');
    }

    .p-button-sm.p-button-icon-only {
        width: dt('button.sm.icon.only.width');
    }

    .p-button-sm.p-button-icon-only.p-button-rounded {
        height: dt('button.sm.icon.only.width');
    }

    .p-button-lg {
        font-size: dt('button.lg.font.size');
        padding: dt('button.lg.padding.y') dt('button.lg.padding.x');
    }

    .p-button-lg .p-button-icon {
        font-size: dt('button.lg.font.size');
    }

    .p-button-lg.p-button-icon-only {
        width: dt('button.lg.icon.only.width');
    }

    .p-button-lg.p-button-icon-only.p-button-rounded {
        height: dt('button.lg.icon.only.width');
    }

    .p-button-vertical {
        flex-direction: column;
    }

    .p-button-label {
        font-weight: dt('button.label.font.weight');
    }

    .p-button-fluid {
        width: 100%;
    }

    .p-button-fluid.p-button-icon-only {
        width: dt('button.icon.only.width');
    }

    .p-button:not(:disabled):hover {
        background: dt('button.primary.hover.background');
        border: 1px solid dt('button.primary.hover.border.color');
        color: dt('button.primary.hover.color');
    }

    .p-button:not(:disabled):active {
        background: dt('button.primary.active.background');
        border: 1px solid dt('button.primary.active.border.color');
        color: dt('button.primary.active.color');
    }

    .p-button:focus-visible {
        box-shadow: dt('button.primary.focus.ring.shadow');
        outline: dt('button.focus.ring.width') dt('button.focus.ring.style') dt('button.primary.focus.ring.color');
        outline-offset: dt('button.focus.ring.offset');
    }

    .p-button .p-badge {
        min-width: dt('button.badge.size');
        height: dt('button.badge.size');
        line-height: dt('button.badge.size');
    }

    .p-button-raised {
        box-shadow: dt('button.raised.shadow');
    }

    .p-button-rounded {
        border-radius: dt('button.rounded.border.radius');
    }

    .p-button-secondary {
        background: dt('button.secondary.background');
        border: 1px solid dt('button.secondary.border.color');
        color: dt('button.secondary.color');
    }

    .p-button-secondary:not(:disabled):hover {
        background: dt('button.secondary.hover.background');
        border: 1px solid dt('button.secondary.hover.border.color');
        color: dt('button.secondary.hover.color');
    }

    .p-button-secondary:not(:disabled):active {
        background: dt('button.secondary.active.background');
        border: 1px solid dt('button.secondary.active.border.color');
        color: dt('button.secondary.active.color');
    }

    .p-button-secondary:focus-visible {
        outline-color: dt('button.secondary.focus.ring.color');
        box-shadow: dt('button.secondary.focus.ring.shadow');
    }

    .p-button-success {
        background: dt('button.success.background');
        border: 1px solid dt('button.success.border.color');
        color: dt('button.success.color');
    }

    .p-button-success:not(:disabled):hover {
        background: dt('button.success.hover.background');
        border: 1px solid dt('button.success.hover.border.color');
        color: dt('button.success.hover.color');
    }

    .p-button-success:not(:disabled):active {
        background: dt('button.success.active.background');
        border: 1px solid dt('button.success.active.border.color');
        color: dt('button.success.active.color');
    }

    .p-button-success:focus-visible {
        outline-color: dt('button.success.focus.ring.color');
        box-shadow: dt('button.success.focus.ring.shadow');
    }

    .p-button-info {
        background: dt('button.info.background');
        border: 1px solid dt('button.info.border.color');
        color: dt('button.info.color');
    }

    .p-button-info:not(:disabled):hover {
        background: dt('button.info.hover.background');
        border: 1px solid dt('button.info.hover.border.color');
        color: dt('button.info.hover.color');
    }

    .p-button-info:not(:disabled):active {
        background: dt('button.info.active.background');
        border: 1px solid dt('button.info.active.border.color');
        color: dt('button.info.active.color');
    }

    .p-button-info:focus-visible {
        outline-color: dt('button.info.focus.ring.color');
        box-shadow: dt('button.info.focus.ring.shadow');
    }

    .p-button-warn {
        background: dt('button.warn.background');
        border: 1px solid dt('button.warn.border.color');
        color: dt('button.warn.color');
    }

    .p-button-warn:not(:disabled):hover {
        background: dt('button.warn.hover.background');
        border: 1px solid dt('button.warn.hover.border.color');
        color: dt('button.warn.hover.color');
    }

    .p-button-warn:not(:disabled):active {
        background: dt('button.warn.active.background');
        border: 1px solid dt('button.warn.active.border.color');
        color: dt('button.warn.active.color');
    }

    .p-button-warn:focus-visible {
        outline-color: dt('button.warn.focus.ring.color');
        box-shadow: dt('button.warn.focus.ring.shadow');
    }

    .p-button-help {
        background: dt('button.help.background');
        border: 1px solid dt('button.help.border.color');
        color: dt('button.help.color');
    }

    .p-button-help:not(:disabled):hover {
        background: dt('button.help.hover.background');
        border: 1px solid dt('button.help.hover.border.color');
        color: dt('button.help.hover.color');
    }

    .p-button-help:not(:disabled):active {
        background: dt('button.help.active.background');
        border: 1px solid dt('button.help.active.border.color');
        color: dt('button.help.active.color');
    }

    .p-button-help:focus-visible {
        outline-color: dt('button.help.focus.ring.color');
        box-shadow: dt('button.help.focus.ring.shadow');
    }

    .p-button-danger {
        background: dt('button.danger.background');
        border: 1px solid dt('button.danger.border.color');
        color: dt('button.danger.color');
    }

    .p-button-danger:not(:disabled):hover {
        background: dt('button.danger.hover.background');
        border: 1px solid dt('button.danger.hover.border.color');
        color: dt('button.danger.hover.color');
    }

    .p-button-danger:not(:disabled):active {
        background: dt('button.danger.active.background');
        border: 1px solid dt('button.danger.active.border.color');
        color: dt('button.danger.active.color');
    }

    .p-button-danger:focus-visible {
        outline-color: dt('button.danger.focus.ring.color');
        box-shadow: dt('button.danger.focus.ring.shadow');
    }

    .p-button-contrast {
        background: dt('button.contrast.background');
        border: 1px solid dt('button.contrast.border.color');
        color: dt('button.contrast.color');
    }

    .p-button-contrast:not(:disabled):hover {
        background: dt('button.contrast.hover.background');
        border: 1px solid dt('button.contrast.hover.border.color');
        color: dt('button.contrast.hover.color');
    }

    .p-button-contrast:not(:disabled):active {
        background: dt('button.contrast.active.background');
        border: 1px solid dt('button.contrast.active.border.color');
        color: dt('button.contrast.active.color');
    }

    .p-button-contrast:focus-visible {
        outline-color: dt('button.contrast.focus.ring.color');
        box-shadow: dt('button.contrast.focus.ring.shadow');
    }

    .p-button-outlined {
        background: transparent;
        border-color: dt('button.outlined.primary.border.color');
        color: dt('button.outlined.primary.color');
    }

    .p-button-outlined:not(:disabled):hover {
        background: dt('button.outlined.primary.hover.background');
        border-color: dt('button.outlined.primary.border.color');
        color: dt('button.outlined.primary.color');
    }

    .p-button-outlined:not(:disabled):active {
        background: dt('button.outlined.primary.active.background');
        border-color: dt('button.outlined.primary.border.color');
        color: dt('button.outlined.primary.color');
    }

    .p-button-outlined.p-button-secondary {
        border-color: dt('button.outlined.secondary.border.color');
        color: dt('button.outlined.secondary.color');
    }

    .p-button-outlined.p-button-secondary:not(:disabled):hover {
        background: dt('button.outlined.secondary.hover.background');
        border-color: dt('button.outlined.secondary.border.color');
        color: dt('button.outlined.secondary.color');
    }

    .p-button-outlined.p-button-secondary:not(:disabled):active {
        background: dt('button.outlined.secondary.active.background');
        border-color: dt('button.outlined.secondary.border.color');
        color: dt('button.outlined.secondary.color');
    }

    .p-button-outlined.p-button-success {
        border-color: dt('button.outlined.success.border.color');
        color: dt('button.outlined.success.color');
    }

    .p-button-outlined.p-button-success:not(:disabled):hover {
        background: dt('button.outlined.success.hover.background');
        border-color: dt('button.outlined.success.border.color');
        color: dt('button.outlined.success.color');
    }

    .p-button-outlined.p-button-success:not(:disabled):active {
        background: dt('button.outlined.success.active.background');
        border-color: dt('button.outlined.success.border.color');
        color: dt('button.outlined.success.color');
    }

    .p-button-outlined.p-button-info {
        border-color: dt('button.outlined.info.border.color');
        color: dt('button.outlined.info.color');
    }

    .p-button-outlined.p-button-info:not(:disabled):hover {
        background: dt('button.outlined.info.hover.background');
        border-color: dt('button.outlined.info.border.color');
        color: dt('button.outlined.info.color');
    }

    .p-button-outlined.p-button-info:not(:disabled):active {
        background: dt('button.outlined.info.active.background');
        border-color: dt('button.outlined.info.border.color');
        color: dt('button.outlined.info.color');
    }

    .p-button-outlined.p-button-warn {
        border-color: dt('button.outlined.warn.border.color');
        color: dt('button.outlined.warn.color');
    }

    .p-button-outlined.p-button-warn:not(:disabled):hover {
        background: dt('button.outlined.warn.hover.background');
        border-color: dt('button.outlined.warn.border.color');
        color: dt('button.outlined.warn.color');
    }

    .p-button-outlined.p-button-warn:not(:disabled):active {
        background: dt('button.outlined.warn.active.background');
        border-color: dt('button.outlined.warn.border.color');
        color: dt('button.outlined.warn.color');
    }

    .p-button-outlined.p-button-help {
        border-color: dt('button.outlined.help.border.color');
        color: dt('button.outlined.help.color');
    }

    .p-button-outlined.p-button-help:not(:disabled):hover {
        background: dt('button.outlined.help.hover.background');
        border-color: dt('button.outlined.help.border.color');
        color: dt('button.outlined.help.color');
    }

    .p-button-outlined.p-button-help:not(:disabled):active {
        background: dt('button.outlined.help.active.background');
        border-color: dt('button.outlined.help.border.color');
        color: dt('button.outlined.help.color');
    }

    .p-button-outlined.p-button-danger {
        border-color: dt('button.outlined.danger.border.color');
        color: dt('button.outlined.danger.color');
    }

    .p-button-outlined.p-button-danger:not(:disabled):hover {
        background: dt('button.outlined.danger.hover.background');
        border-color: dt('button.outlined.danger.border.color');
        color: dt('button.outlined.danger.color');
    }

    .p-button-outlined.p-button-danger:not(:disabled):active {
        background: dt('button.outlined.danger.active.background');
        border-color: dt('button.outlined.danger.border.color');
        color: dt('button.outlined.danger.color');
    }

    .p-button-outlined.p-button-contrast {
        border-color: dt('button.outlined.contrast.border.color');
        color: dt('button.outlined.contrast.color');
    }

    .p-button-outlined.p-button-contrast:not(:disabled):hover {
        background: dt('button.outlined.contrast.hover.background');
        border-color: dt('button.outlined.contrast.border.color');
        color: dt('button.outlined.contrast.color');
    }

    .p-button-outlined.p-button-contrast:not(:disabled):active {
        background: dt('button.outlined.contrast.active.background');
        border-color: dt('button.outlined.contrast.border.color');
        color: dt('button.outlined.contrast.color');
    }

    .p-button-outlined.p-button-plain {
        border-color: dt('button.outlined.plain.border.color');
        color: dt('button.outlined.plain.color');
    }

    .p-button-outlined.p-button-plain:not(:disabled):hover {
        background: dt('button.outlined.plain.hover.background');
        border-color: dt('button.outlined.plain.border.color');
        color: dt('button.outlined.plain.color');
    }

    .p-button-outlined.p-button-plain:not(:disabled):active {
        background: dt('button.outlined.plain.active.background');
        border-color: dt('button.outlined.plain.border.color');
        color: dt('button.outlined.plain.color');
    }

    .p-button-text {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.primary.color');
    }

    .p-button-text:not(:disabled):hover {
        background: dt('button.text.primary.hover.background');
        border-color: transparent;
        color: dt('button.text.primary.color');
    }

    .p-button-text:not(:disabled):active {
        background: dt('button.text.primary.active.background');
        border-color: transparent;
        color: dt('button.text.primary.color');
    }

    .p-button-text.p-button-secondary {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.secondary.color');
    }

    .p-button-text.p-button-secondary:not(:disabled):hover {
        background: dt('button.text.secondary.hover.background');
        border-color: transparent;
        color: dt('button.text.secondary.color');
    }

    .p-button-text.p-button-secondary:not(:disabled):active {
        background: dt('button.text.secondary.active.background');
        border-color: transparent;
        color: dt('button.text.secondary.color');
    }

    .p-button-text.p-button-success {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.success.color');
    }

    .p-button-text.p-button-success:not(:disabled):hover {
        background: dt('button.text.success.hover.background');
        border-color: transparent;
        color: dt('button.text.success.color');
    }

    .p-button-text.p-button-success:not(:disabled):active {
        background: dt('button.text.success.active.background');
        border-color: transparent;
        color: dt('button.text.success.color');
    }

    .p-button-text.p-button-info {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.info.color');
    }

    .p-button-text.p-button-info:not(:disabled):hover {
        background: dt('button.text.info.hover.background');
        border-color: transparent;
        color: dt('button.text.info.color');
    }

    .p-button-text.p-button-info:not(:disabled):active {
        background: dt('button.text.info.active.background');
        border-color: transparent;
        color: dt('button.text.info.color');
    }

    .p-button-text.p-button-warn {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.warn.color');
    }

    .p-button-text.p-button-warn:not(:disabled):hover {
        background: dt('button.text.warn.hover.background');
        border-color: transparent;
        color: dt('button.text.warn.color');
    }

    .p-button-text.p-button-warn:not(:disabled):active {
        background: dt('button.text.warn.active.background');
        border-color: transparent;
        color: dt('button.text.warn.color');
    }

    .p-button-text.p-button-help {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.help.color');
    }

    .p-button-text.p-button-help:not(:disabled):hover {
        background: dt('button.text.help.hover.background');
        border-color: transparent;
        color: dt('button.text.help.color');
    }

    .p-button-text.p-button-help:not(:disabled):active {
        background: dt('button.text.help.active.background');
        border-color: transparent;
        color: dt('button.text.help.color');
    }

    .p-button-text.p-button-danger {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.danger.color');
    }

    .p-button-text.p-button-danger:not(:disabled):hover {
        background: dt('button.text.danger.hover.background');
        border-color: transparent;
        color: dt('button.text.danger.color');
    }

    .p-button-text.p-button-danger:not(:disabled):active {
        background: dt('button.text.danger.active.background');
        border-color: transparent;
        color: dt('button.text.danger.color');
    }

    .p-button-text.p-button-contrast {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.contrast.color');
    }

    .p-button-text.p-button-contrast:not(:disabled):hover {
        background: dt('button.text.contrast.hover.background');
        border-color: transparent;
        color: dt('button.text.contrast.color');
    }

    .p-button-text.p-button-contrast:not(:disabled):active {
        background: dt('button.text.contrast.active.background');
        border-color: transparent;
        color: dt('button.text.contrast.color');
    }

    .p-button-text.p-button-plain {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.plain.color');
    }

    .p-button-text.p-button-plain:not(:disabled):hover {
        background: dt('button.text.plain.hover.background');
        border-color: transparent;
        color: dt('button.text.plain.color');
    }

    .p-button-text.p-button-plain:not(:disabled):active {
        background: dt('button.text.plain.active.background');
        border-color: transparent;
        color: dt('button.text.plain.color');
    }

    .p-button-link {
        background: transparent;
        border-color: transparent;
        color: dt('button.link.color');
    }

    .p-button-link:not(:disabled):hover {
        background: transparent;
        border-color: transparent;
        color: dt('button.link.hover.color');
    }

    .p-button-link:not(:disabled):hover .p-button-label {
        text-decoration: underline;
    }

    .p-button-link:not(:disabled):active {
        background: transparent;
        border-color: transparent;
        color: dt('button.link.active.color');
    }
`;function _t(t){"@babel/helpers - typeof";return _t=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},_t(t)}function J(t,e,n){return(e=Un(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Un(t){var e=Wn(t,"string");return _t(e)=="symbol"?e:e+""}function Wn(t,e){if(_t(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(_t(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Hn={root:function(e){var n=e.instance,r=e.props;return["p-button p-component",J(J(J(J(J(J(J(J(J({"p-button-icon-only":n.hasIcon&&!r.label&&!r.badge,"p-button-vertical":(r.iconPos==="top"||r.iconPos==="bottom")&&r.label,"p-button-loading":r.loading,"p-button-link":r.link||r.variant==="link"},"p-button-".concat(r.severity),r.severity),"p-button-raised",r.raised),"p-button-rounded",r.rounded),"p-button-text",r.text||r.variant==="text"),"p-button-outlined",r.outlined||r.variant==="outlined"),"p-button-sm",r.size==="small"),"p-button-lg",r.size==="large"),"p-button-plain",r.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(e){var n=e.props;return["p-button-icon",J({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},Fn=W.extend({name:"button",style:Rn,classes:Hn}),Gn={name:"BaseButton",extends:Gt,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:Fn,provide:function(){return{$pcButton:this,$parentInstance:this}}};function Pt(t){"@babel/helpers - typeof";return Pt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Pt(t)}function G(t,e,n){return(e=Kn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Kn(t){var e=qn(t,"string");return Pt(e)=="symbol"?e:e+""}function qn(t,e){if(Pt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(Pt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var st={name:"Button",extends:Gn,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(e){var n=e==="root"?this.ptmi:this.ptm;return n(e,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return K(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return At(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return yt(G(G(G(G(G(G(G(G(G(G({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return yt(G(G({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return yt(G(G({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:me,Badge:ye},directives:{ripple:Mn}},Yn=["data-p"],Xn=["data-p"];function Qn(t,e,n,r,o,a){var l=Xt("SpinnerIcon"),s=Xt("Badge"),i=Ce("ripple");return t.asChild?ht(t.$slots,"default",{key:1,class:Z(t.cx("root")),a11yAttrs:a.a11yAttrs}):Te((b(),lt(Oe(t.as),K({key:0,class:t.cx("root"),"data-p":a.dataP},a.attrs),{default:it(function(){return[ht(t.$slots,"default",{},function(){return[t.loading?ht(t.$slots,"loadingicon",K({key:0,class:[t.cx("loadingIcon"),t.cx("icon")]},t.ptm("loadingIcon")),function(){return[t.loadingIcon?(b(),v("span",K({key:0,class:[t.cx("loadingIcon"),t.cx("icon"),t.loadingIcon]},t.ptm("loadingIcon")),null,16)):(b(),lt(l,K({key:1,class:[t.cx("loadingIcon"),t.cx("icon")],spin:""},t.ptm("loadingIcon")),null,16,["class"]))]}):ht(t.$slots,"icon",K({key:1,class:[t.cx("icon")]},t.ptm("icon")),function(){return[t.icon?(b(),v("span",K({key:0,class:[t.cx("icon"),t.icon,t.iconClass],"data-p":a.dataIconP},t.ptm("icon")),null,16,Yn)):V("",!0)]}),t.label?(b(),v("span",K({key:2,class:t.cx("label")},t.ptm("label"),{"data-p":a.dataLabelP}),y(t.label),17,Xn)):V("",!0),t.badge?(b(),lt(s,{key:3,value:t.badge,class:Z(t.badgeClass),severity:t.badgeSeverity,unstyled:t.unstyled,pt:t.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):V("",!0)]})]}),_:3},16,["class","data-p"])),[[i]])}st.render=Qn;const Zn={class:"px-5 py-2.5 border-b flex items-center gap-3 text-[12px]",style:{"border-color":"var(--p-content-border-color)"}},Jn=["disabled"],to=["disabled"],eo={class:"flex items-center gap-1 cursor-pointer text-[10px] opacity-70 hover:opacity-100",title:"Sync registry overlays to disk before scanning git"},no=["checked"],oo={class:"opacity-70"},ro={key:1,class:"ml-auto opacity-60 text-[11px]"},ao={key:2,class:"ml-auto opacity-50 text-[11px]"},io=bt({__name:"GitHeader",props:{stale:{type:Boolean},rebuilding:{type:Boolean},indexAgeText:{},journalSize:{},counts:{},syncFirst:{type:Boolean}},emits:["rebuild","push-confirm","update:syncFirst"],setup(t,{emit:e}){const n=e;return(r,o)=>(b(),v("header",Zn,[S(f(I),{icon:"tabler:git-pull-request",class:"w-4 h-4"}),o[6]||(o[6]=u("h1",{class:"text-[13px] font-semibold"},"Git",-1)),o[7]||(o[7]=u("span",{class:"opacity-50"},"·",-1)),u("div",{class:Z(["flex items-center gap-2 px-2 py-1 rounded",{"bg-warn-500/10":t.stale}]),style:F(t.stale?{}:{background:"var(--p-content-hover-background)"})},[S(f(I),{icon:t.stale?"tabler:alert-triangle":"tabler:database",class:Z(["w-3.5 h-3.5",{"text-warn-500":t.stale}])},null,8,["icon","class"]),u("span",{class:Z(["text-[11px]",{"text-warn-500":t.stale}])},[A(" Index built "+y(t.indexAgeText)+" ",1),t.journalSize!==null?(b(),v(X,{key:0},[A(" · "+y(t.journalSize)+" changes ",1)],64)):V("",!0)],2),u("button",{onClick:o[0]||(o[0]=a=>n("rebuild","ai")),disabled:t.rebuilding,class:Z(["text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1 text-white",{"bg-warn-500":t.stale}]),style:F(t.stale?{}:{background:"var(--p-primary-color)"}),title:"AI-clustered rebuild — groups changes by topic via Sonnet (~30-90s)"},[S(f(I),{icon:t.rebuilding?"tabler:loader-2":"tabler:sparkles",class:Z(t.rebuilding?"w-3 h-3 animate-spin":"w-3 h-3")},null,8,["icon","class"]),A(" "+y(t.rebuilding?"Rebuilding…":"AI rebuild"),1)],14,Jn),u("button",{onClick:o[1]||(o[1]=a=>n("rebuild","manual")),disabled:t.rebuilding,class:"text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1",style:{background:"var(--kp-btn-secondary-bg)"},title:"Manual rebuild — group by directory prefix (no LLM, instant)"},[S(f(I),{icon:"tabler:list",class:"w-3 h-3"}),o[4]||(o[4]=A(" Manual ",-1))],8,to),u("label",eo,[u("input",{type:"checkbox",checked:t.syncFirst,onChange:o[2]||(o[2]=a=>n("update:syncFirst",a.target.checked)),class:"w-3 h-3"},null,40,no),o[5]||(o[5]=A(" sync first ",-1))])],6),o[8]||(o[8]=u("span",{class:"opacity-50"},"·",-1)),u("span",oo,y(t.counts.all)+" clusters · "+y(t.counts.suspect)+" suspect",1),(t.counts.pushable_ready||0)>0?(b(),lt(f(st),{key:0,onClick:o[3]||(o[3]=a=>n("push-confirm")),severity:"success",class:"ml-auto !px-3 !py-1 !text-[11px] !font-semibold !gap-1.5"},{default:it(()=>[S(f(I),{icon:"tabler:upload",class:"w-3.5 h-3.5"}),A(" Push "+y(t.counts.pushable_ready)+" ready ",1)]),_:1})):(t.counts.blocked_ready||0)>0?(b(),v("span",ro,y(t.counts.blocked_ready)+" ready for review only ",1)):(b(),v("span",ao," Mark clusters ready to enable push "))]))}}),so={class:"flex flex-col"},lo={class:"px-5 py-2 border-b flex items-center gap-1 text-[10px]",style:{"border-color":"var(--p-content-border-color)"}},uo=["onClick"],co={class:"opacity-80"},po={class:"flex-1 overflow-y-auto border-r",style:{"border-color":"var(--p-content-border-color)"}},bo={key:0,class:"p-8 text-center text-[12px] opacity-60"},go={key:1,class:"p-6 text-[12px] text-danger-500"},fo={key:2,class:"p-12 text-center text-[12px] opacity-60"},vo={key:0},ho={key:1},mo=["onClick"],yo={class:"flex items-center gap-2 mb-1.5"},xo={class:"text-[12px] font-semibold flex-1 truncate"},ko={class:"flex items-center gap-2 text-[10px] opacity-70 mb-1"},$o={key:0,class:"ml-auto text-[9px] px-1 rounded bg-warn-500/10 text-warn-500"},wo={class:"text-[10px] opacity-70 leading-snug truncate"},So=bt({__name:"GitClusterList",props:{clusters:{},counts:{},filter:{},selectedId:{},loading:{type:Boolean},error:{},hasAnyClusters:{type:Boolean}},emits:["update:filter","select"],setup(t,{emit:e}){const n=e,r=[{key:"all",label:"All"},{key:"pending",label:"Pending"},{key:"ready",label:"Ready to push"},{key:"hidden",label:"Hidden"},{key:"suspect",label:"Suspect"}];return(o,a)=>(b(),v("div",so,[u("div",lo,[(b(),v(X,null,et(r,l=>u("button",{key:l.key,onClick:s=>n("update:filter",l.key),class:"px-1.5 py-0.5 rounded font-medium flex items-center gap-1 transition",style:F({background:t.filter===l.key?"var(--p-primary-color)":"var(--p-content-hover-background)",color:t.filter===l.key?"var(--p-primary-contrast-color)":"inherit"})},[A(y(l.label)+" ",1),u("span",co,y(t.counts[l.key]),1)],12,uo)),64))]),u("section",po,[t.loading&&!t.hasAnyClusters?(b(),v("div",bo," Loading… ")):t.error?(b(),v("div",go,y(t.error),1)):t.clusters.length===0?(b(),v("div",fo,[t.hasAnyClusters?(b(),v("span",ho,"Nothing matches.")):(b(),v("span",vo," No cluster index yet. Click Rebuild above to build one. "))])):V("",!0),(b(!0),v(X,null,et(t.clusters,l=>(b(),v("article",{key:l.id,onClick:s=>n("select",l.id),class:"px-4 py-3 border-b cursor-pointer transition",style:F({borderColor:"var(--p-content-border-color)",background:t.selectedId===l.id?"var(--p-content-hover-background)":"transparent",opacity:l.decision!=="pending"?.65:1})},[u("div",yo,[u("span",{class:"w-2 h-2 rounded-full shrink-0",style:F({background:f(Ot)[l.importance].dot})},null,4),u("h3",xo,y(l.title),1),l.decision==="approved"?(b(),lt(f(I),{key:0,icon:"tabler:circle-check",class:"w-3.5 h-3.5 shrink-0 text-success-500"})):l.decision==="split"?(b(),lt(f(I),{key:1,icon:"tabler:arrow-split",class:"w-3.5 h-3.5 shrink-0 opacity-50"})):l.decision==="skipped"?(b(),lt(f(I),{key:2,icon:"tabler:archive",class:"w-3.5 h-3.5 shrink-0 opacity-50"})):V("",!0)]),u("div",ko,[u("span",null,y(f(Ft)(l.change_count)),1),a[0]||(a[0]=u("span",{class:"opacity-50"},"·",-1)),u("span",{class:"flex items-center gap-1",style:F({color:f(at)[l.verdict].color})},[S(f(I),{icon:f(at)[l.verdict].icon,class:"w-3 h-3"},null,8,["icon"]),A(" "+y(f(at)[l.verdict].phrase),1)],4),l.rec_open>0?(b(),v("span",$o,y(l.rec_open)+" open ",1)):V("",!0)]),u("p",wo,y(l.plain_summary),1)],12,mo))),128))])]))}}),_o={class:"overflow-y-auto",style:{background:"var(--p-content-background)"}},Po={class:"p-6"},Co={class:"flex items-center gap-2 mb-2"},To={class:"text-[11px] opacity-70"},Oo={class:"text-[11px] opacity-70"},Ao={key:0,class:"text-[11px] opacity-50"},jo={key:1,class:"text-[11px] opacity-70"},Io={class:"ml-auto text-[10px] opacity-50 font-mono"},Eo={class:"text-[20px] font-semibold mb-2"},Lo={class:"text-[13px] opacity-85 leading-relaxed mb-4"},Bo={class:"text-[11px] opacity-80"},No={key:0,class:"mb-5"},Do={class:"text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5"},Vo={key:0,class:"space-y-1.5"},zo={class:"flex-1 min-w-0"},Mo={class:"text-[12px]"},Ro={key:0,class:"text-[11px] opacity-70 mt-0.5"},Uo={key:1,class:"flex gap-1 mt-2 flex-wrap"},Wo={key:2,class:"mt-2 p-2.5 rounded text-[11px] leading-relaxed whitespace-pre-wrap border-l-[3px] border-accent-500",style:{background:"var(--p-content-hover-background)"}},Ho={class:"text-[9px] uppercase tracking-wide opacity-60 mb-1 flex items-center gap-1"},Fo={key:1,class:"mb-5"},Go={class:"text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5"},Ko={class:"rounded border",style:{"border-color":"var(--p-content-border-color)"}},qo=["onClick"],Yo={class:"font-mono text-[11px] flex-1 truncate"},Xo={key:0,class:"text-[10px] shrink-0 text-success-500"},Qo={key:1,class:"text-[10px] shrink-0 text-danger-500"},Zo={key:0,class:"px-3 py-1.5 text-[10px] opacity-60"},Jo={class:"sticky bottom-0 -mx-6 px-6 py-3 border-t flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)",background:"var(--p-content-background)"}},tr={key:0,class:"text-[11px] ml-2 text-danger-500"},er={class:"text-[11px] flex items-center gap-1.5 text-success-500"},nr={key:1,class:"ml-auto text-[11px] opacity-60"},or=bt({__name:"GitClusterDetail",props:{cluster:{},changes:{},blocking:{type:Boolean},pushableReady:{},expandedRecs:{type:Boolean},explaining:{},explanations:{}},emits:["decide","ack-rec","explain-rec","open-split","open-diff","push-confirm","update:expandedRecs"],setup(t,{emit:e}){const n=e;return(r,o)=>(b(),v("section",_o,[u("article",Po,[u("div",Co,[u("span",{class:"w-2 h-2 rounded-full",style:F({background:f(Ot)[t.cluster.importance].dot})},null,4),u("span",To,y(f(Ot)[t.cluster.importance].word),1),o[7]||(o[7]=u("span",{class:"text-[11px] opacity-50"},"·",-1)),u("span",Oo,y(f(Ft)(t.cluster.change_count)),1),t.cluster.stats?(b(),v("span",Ao,"·")):V("",!0),t.cluster.stats?(b(),v("span",jo,y(t.cluster.stats.namespaces?.length||0)+" namespace"+y((t.cluster.stats.namespaces?.length||0)===1?"":"s"),1)):V("",!0),u("span",Io,y(t.cluster.id),1)]),u("h2",Eo,y(t.cluster.title),1),u("p",Lo,y(t.cluster.plain_summary),1),u("div",{class:"rounded-lg p-3 mb-4 flex items-center gap-3",style:F({background:f(at)[t.cluster.verdict].bg,border:"1px solid "+f(at)[t.cluster.verdict].border})},[S(f(I),{icon:f(at)[t.cluster.verdict].icon,class:"w-5 h-5",style:F({color:f(at)[t.cluster.verdict].color})},null,8,["icon","style"]),u("div",null,[u("div",{class:"text-[12px] font-semibold",style:F({color:f(at)[t.cluster.verdict].color})},y(f(at)[t.cluster.verdict].phrase),5),u("div",Bo,y(t.cluster.verdict_text),1)])],4),t.cluster.recommendations?(b(),v("div",No,[u("h3",Do,[S(f(I),{icon:"tabler:sparkles",class:"w-3 h-3"}),o[8]||(o[8]=A(" AI recommendations ",-1)),u("button",{onClick:o[0]||(o[0]=a=>n("update:expandedRecs",!t.expandedRecs)),class:"ml-auto text-[10px] opacity-60 hover:opacity-100"},y(t.expandedRecs?"Collapse":"Expand"),1)]),t.expandedRecs?(b(),v("ul",Vo,[(b(!0),v(X,null,et(t.cluster.recommendations,a=>(b(),v("li",{key:a.id,class:"rounded p-2.5 flex items-start gap-2",style:F({background:f(Lt)[a.severity].bg,border:"1px solid var(--p-content-border-color)"})},[S(f(I),{icon:f(Lt)[a.severity].icon,class:"w-3.5 h-3.5 shrink-0 mt-0.5",style:F({color:f(Lt)[a.severity].color})},null,8,["icon","style"]),u("div",zo,[u("div",Mo,y(a.text),1),a.fix_hint?(b(),v("div",Ro,"↳ "+y(a.fix_hint),1)):V("",!0),a.state==="open"?(b(),v("div",Uo,[S(f(st),{onClick:l=>n("explain-rec",a.id),disabled:t.explaining===a.id,class:"!gap-1 k-btn-tinted k-btn-tinted-accent"},{default:it(()=>[S(f(I),{icon:t.explaining===a.id?"tabler:loader-2":"tabler:sparkles",class:Z(t.explaining===a.id?"w-3 h-3 animate-spin":"w-3 h-3")},null,8,["icon","class"]),A(" "+y(t.explaining===a.id?"Asking AI…":"Explain"),1)]),_:2},1032,["onClick","disabled"]),S(f(st),{onClick:l=>n("ack-rec",a.id,"acknowledged"),class:"!gap-1 k-btn-tinted k-btn-tinted-info"},{default:it(()=>[S(f(I),{icon:"tabler:eye-check",class:"w-3 h-3"}),o[9]||(o[9]=A(" Acknowledge ",-1))]),_:1},8,["onClick"]),S(f(st),{onClick:l=>n("ack-rec",a.id,"fixed"),class:"!gap-1 k-btn-tinted k-btn-tinted-success"},{default:it(()=>[S(f(I),{icon:"tabler:check",class:"w-3 h-3"}),o[10]||(o[10]=A(" Mark fixed ",-1))]),_:1},8,["onClick"])])):V("",!0),a.detail||t.explanations[a.id]?(b(),v("div",Wo,[u("div",Ho,[S(f(I),{icon:"tabler:sparkles",class:"w-3 h-3"}),o[11]||(o[11]=A(" AI explanation ",-1))]),A(y(a.detail||t.explanations[a.id]),1)])):V("",!0)]),u("span",{class:"text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0",style:F({background:f(Bt)[a.state].bg,color:f(Bt)[a.state].color})},y(f(Bt)[a.state].label),5)],4))),128))])):V("",!0)])):V("",!0),t.changes.length>0?(b(),v("div",Fo,[u("h3",Go,[S(f(I),{icon:"tabler:list",class:"w-3 h-3"}),A(" Changes ("+y(t.changes.length)+") ",1),o[12]||(o[12]=u("span",{class:"opacity-50 ml-auto text-[9px]"},"click a row for diff",-1))]),u("div",Ko,[(b(!0),v(X,null,et(t.changes.slice(0,100),a=>(b(),v("div",{key:a.change_id,onClick:l=>n("open-diff",a.path),class:"px-3 py-1.5 border-b last:border-0 flex items-center gap-2 cursor-pointer hover:bg-[var(--p-content-hover-background)]",style:{"border-color":"var(--p-content-border-color)"}},[u("span",{class:Z(["text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0",{"bg-success-500/10 text-success-500":a.op==="create","bg-danger-500/10 text-danger-500":a.op==="delete","bg-info-500/10 text-info-500":a.op!=="create"&&a.op!=="delete"}])},y(a.op[0].toUpperCase()),3),S(f(I),{icon:a.category==="registry"?"tabler:database":"tabler:file",class:"w-3 h-3 opacity-50 shrink-0"},null,8,["icon"]),u("span",Yo,y(a.path),1),a.added?(b(),v("span",Xo,"+"+y(a.added),1)):V("",!0),a.removed?(b(),v("span",Qo,"−"+y(a.removed),1)):V("",!0)],8,qo))),128)),t.changes.length>100?(b(),v("div",Zo," + "+y(t.changes.length-100)+" more ",1)):V("",!0)])])):V("",!0),u("div",Jo,[t.cluster.decision==="pending"?(b(),v(X,{key:0},[S(f(st),{onClick:o[1]||(o[1]=a=>n("decide",t.cluster.id,"approved")),disabled:t.blocking,severity:"success",class:"!px-4 !py-2 !rounded-lg !text-[12px] !font-medium !gap-1.5"},{default:it(()=>[S(f(I),{icon:"tabler:check",class:"w-3.5 h-3.5"}),o[13]||(o[13]=A(" Mark ready ",-1))]),_:1},8,["disabled"]),u("button",{onClick:o[2]||(o[2]=a=>n("open-split")),class:"px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5",style:{background:"var(--kp-btn-secondary-bg)"}},[S(f(I),{icon:"tabler:arrow-split",class:"w-3.5 h-3.5"}),o[14]||(o[14]=A(" Split… ",-1))]),u("button",{onClick:o[3]||(o[3]=a=>n("decide",t.cluster.id,"skipped")),class:"px-4 py-2 rounded-lg text-[12px] flex items-center gap-1.5",style:{background:"var(--kp-btn-secondary-bg)"}},[S(f(I),{icon:"tabler:archive",class:"w-3.5 h-3.5"}),o[15]||(o[15]=A(" Hide ",-1))]),t.blocking?(b(),v("span",tr," Resolve blocking issue first ")):V("",!0)],64)):t.cluster.decision==="approved"?(b(),v(X,{key:1},[u("span",er,[S(f(I),{icon:"tabler:circle-check",class:"w-3.5 h-3.5"}),o[16]||(o[16]=A(" Marked ready — push from header when ready to ship ",-1))]),t.cluster.pushable?(b(),lt(f(st),{key:0,onClick:o[4]||(o[4]=a=>n("push-confirm")),severity:"success",class:"ml-auto !px-4 !py-2 !rounded-lg !text-[12px] !font-medium !gap-1.5"},{default:it(()=>[S(f(I),{icon:"tabler:upload",class:"w-3.5 h-3.5"}),A(" Push all "+y(t.pushableReady),1)]),_:1})):(b(),v("span",nr,y(t.cluster.push_blockers?.[0]||"Review-only cluster"),1)),u("button",{onClick:o[5]||(o[5]=a=>n("decide",t.cluster.id,"pending")),class:"px-4 py-2 rounded-lg text-[12px]",style:{background:"var(--kp-btn-secondary-bg)"}}," Unmark ")],64)):(b(),v("button",{key:2,onClick:o[6]||(o[6]=a=>n("decide",t.cluster.id,"pending")),class:"px-4 py-2 rounded-lg text-[12px]",style:{background:"var(--kp-btn-secondary-bg)"}}," Move back to pending "))])])]))}}),rr={class:"rounded-lg w-full max-w-md mx-4 overflow-hidden",style:{background:"var(--p-content-background)",border:"1px solid var(--p-content-border-color)"}},ar={class:"px-5 py-3 border-b flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},ir={class:"text-[13px] font-semibold flex-1"},sr={class:"px-5 py-4"},lr={class:"rounded border mt-3",style:{"border-color":"var(--p-content-border-color)","max-height":"240px","overflow-y":"auto"}},dr={class:"text-[11px] flex-1 truncate"},ur={class:"text-[10px] opacity-60 shrink-0"},cr={class:"px-5 py-3 border-t flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},pr=["disabled"],br=bt({__name:"GitPushConfirmModal",props:{open:{type:Boolean},count:{},pushing:{type:Boolean},clusters:{}},emits:["push","close"],setup(t,{emit:e}){const n=e;return(r,o)=>t.open?(b(),v("div",{key:0,class:"fixed inset-0 z-50 flex items-center justify-center",style:{background:"var(--p-mask-background)"},onClick:o[3]||(o[3]=Ht(a=>n("close"),["self"]))},[u("div",rr,[u("div",ar,[S(f(I),{icon:"tabler:upload",class:"w-4 h-4"}),u("h3",ir,"Push "+y(t.count)+" clusters to main",1),u("button",{onClick:o[0]||(o[0]=a=>n("close")),class:"opacity-60 hover:opacity-100"},[S(f(I),{icon:"tabler:x",class:"w-4 h-4"})])]),u("div",sr,[o[4]||(o[4]=u("p",{class:"text-[11px] opacity-80 leading-relaxed"},[A(" Each cluster runs through governance (lint → version → migrations → tests → registry → fs) and merges to main on success. Failed clusters stay in "),u("b",null,"Pending"),A(" with the failure attached. ")],-1)),u("div",lr,[(b(!0),v(X,null,et(t.clusters,a=>(b(),v("div",{key:a.id,class:"px-3 py-2 border-b last:border-0 flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},[u("span",{class:"w-1.5 h-1.5 rounded-full shrink-0",style:F({background:f(Ot)[a.importance].dot})},null,4),u("span",dr,y(a.title),1),u("span",ur,y(f(Ft)(a.change_count)),1)]))),128))])]),u("div",cr,[S(f(st),{onClick:o[1]||(o[1]=a=>n("push")),disabled:t.pushing,severity:"success",class:"!px-4 !py-1.5 !text-[12px] !font-semibold !gap-1.5"},{default:it(()=>[S(f(I),{icon:t.pushing?"tabler:loader-2":"tabler:upload",class:Z(t.pushing?"w-3.5 h-3.5 animate-spin":"w-3.5 h-3.5")},null,8,["icon","class"]),A(" "+y(t.pushing?"Pushing…":"Push all"),1)]),_:1},8,["disabled"]),u("button",{onClick:o[2]||(o[2]=a=>n("close")),disabled:t.pushing,class:"px-4 py-1.5 rounded text-[12px]",style:{background:"var(--kp-btn-secondary-bg)"}}," Cancel ",8,pr)])])])):V("",!0)}}),gr={class:"rounded-lg w-full max-w-2xl mx-4 overflow-hidden flex flex-col",style:{background:"var(--p-content-background)",border:"1px solid var(--p-content-border-color)","max-height":"80vh"}},fr={class:"px-5 py-3 border-b flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},vr={class:"text-[13px] font-semibold flex-1"},hr={class:"opacity-70"},mr={class:"px-5 py-2.5 border-b flex items-center gap-1 text-[11px]",style:{"border-color":"var(--p-content-border-color)"}},yr=["onClick","disabled"],xr={class:"ml-auto opacity-60"},kr={class:"flex-1 overflow-y-auto p-4"},$r={key:0,class:"p-12 text-center text-[12px] opacity-60"},wr={key:0},Sr={key:1},_r={key:1,class:"p-12 text-center text-[12px] opacity-60"},Pr={key:2},Cr={class:"text-[11px] opacity-70 mb-3"},Tr={class:"space-y-2"},Or={class:"flex items-baseline gap-2 mb-1"},Ar={class:"text-[12px] font-semibold flex-1 truncate"},jr={class:"text-[10px] opacity-70"},Ir={key:0,class:"text-[11px] opacity-80 mb-1.5"},Er={class:"font-mono text-[10px] opacity-60 space-y-0.5"},Lr={key:0},Br={class:"px-5 py-3 border-t flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},Nr=bt({__name:"GitSplitModal",props:{open:{type:Boolean},title:{},changeCount:{},changes:{},mode:{},groups:{},loading:{type:Boolean},applying:{type:Boolean}},emits:["update:mode","apply","close"],setup(t,{emit:e}){const n=t,r=e;function o(l){const s=n.changes;if(!s)return[];const i={};for(const d of s)i[d.change_id]=d.path;return l.change_ids.slice(0,3).map(d=>i[d]||d)}const a=[{key:"by_prefix",icon:"tabler:folders",label:"By directory"},{key:"by_kind",icon:"tabler:category",label:"By file kind"},{key:"ai",icon:"tabler:sparkles",label:"AI suggest"}];return(l,s)=>t.open?(b(),v("div",{key:0,class:"fixed inset-0 z-50 flex items-center justify-center",style:{background:"var(--p-mask-background)"},onClick:s[3]||(s[3]=Ht(i=>r("close"),["self"]))},[u("div",gr,[u("header",fr,[S(f(I),{icon:"tabler:arrow-split",class:"w-4 h-4"}),u("h3",vr,[s[4]||(s[4]=A(" Split ",-1)),u("span",hr,y(t.title),1)]),u("button",{onClick:s[0]||(s[0]=i=>r("close")),class:"opacity-60 hover:opacity-100"},[S(f(I),{icon:"tabler:x",class:"w-4 h-4"})])]),u("div",mr,[s[5]||(s[5]=u("span",{class:"opacity-70 mr-1"},"Strategy:",-1)),(b(),v(X,null,et(a,i=>u("button",{key:i.key,onClick:d=>r("update:mode",i.key),disabled:t.loading,class:"px-2 py-1 rounded font-medium flex items-center gap-1",style:F({background:t.mode===i.key?"var(--p-primary-color)":"var(--p-content-hover-background)",color:t.mode===i.key?"var(--p-primary-contrast-color)":"inherit"})},[S(f(I),{icon:i.icon,class:"w-3 h-3"},null,8,["icon"]),A(" "+y(i.label),1)],12,yr)),64)),u("span",xr,y(t.changeCount)+" files in source cluster ",1)]),u("div",kr,[t.loading?(b(),v("div",$r,[S(f(I),{icon:"tabler:loader-2",class:"w-5 h-5 animate-spin mx-auto mb-2"}),t.mode==="ai"?(b(),v("span",wr,"Asking Sonnet to propose sub-clusters…")):(b(),v("span",Sr,"Computing groups…"))])):t.groups.length===0?(b(),v("div",_r," No groups proposed. ")):(b(),v("div",Pr,[u("p",Cr,[s[6]||(s[6]=A(" Will create ",-1)),u("b",null,y(t.groups.length),1),A(" new clusters. Source cluster will be "+y(t.groups.reduce((i,d)=>i+d.change_ids.length,0)>=t.changeCount?"removed":"reduced")+". ",1)]),u("ul",Tr,[(b(!0),v(X,null,et(t.groups,(i,d)=>(b(),v("li",{key:d,class:"rounded p-3",style:{background:"var(--p-content-hover-background)",border:"1px solid var(--p-content-border-color)"}},[u("div",Or,[u("span",Ar,y(i.title),1),u("span",jr,y(i.change_ids.length)+" files",1)]),i.plain_summary?(b(),v("p",Ir,y(i.plain_summary),1)):V("",!0),u("div",Er,[(b(!0),v(X,null,et(o(i),c=>(b(),v("div",{key:c,class:"truncate"},y(c),1))),128)),i.change_ids.length>3?(b(),v("div",Lr,"+ "+y(i.change_ids.length-3)+" more",1)):V("",!0)])]))),128))])]))]),u("div",Br,[S(f(st),{onClick:s[1]||(s[1]=i=>r("apply")),disabled:t.loading||t.applying||t.groups.length<2,severity:"success",class:"!px-4 !py-1.5 !text-[12px] !font-semibold !gap-1.5"},{default:it(()=>[S(f(I),{icon:t.applying?"tabler:loader-2":"tabler:arrow-split",class:Z(t.applying?"w-3.5 h-3.5 animate-spin":"w-3.5 h-3.5")},null,8,["icon","class"]),A(" "+y(t.applying?"Splitting…":`Apply (creates ${t.groups.length} clusters)`),1)]),_:1},8,["disabled"]),u("button",{onClick:s[2]||(s[2]=i=>r("close")),class:"px-4 py-1.5 rounded text-[12px] ml-auto",style:{background:"var(--kp-btn-secondary-bg)"}},"Cancel")])])])):V("",!0)}}),Dr={class:"ml-auto w-[820px] h-full overflow-hidden flex flex-col",style:{background:"var(--p-content-background)","border-left":"1px solid var(--p-content-border-color)"}},Vr={class:"px-4 py-2.5 border-b flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},zr={class:"text-[11px] font-mono flex-1 truncate"},Mr={key:0,class:"p-12 text-center text-[12px] opacity-60"},Rr={key:1,class:"p-12 text-center text-[12px] opacity-60"},Ur={key:2,class:"flex-1 overflow-y-auto font-mono text-[11px] leading-snug"},Wr={class:"px-3 py-1 sticky top-0 z-10 text-[10px] opacity-60",style:{background:"var(--p-content-hover-background)","border-bottom":"1px solid var(--p-content-border-color)"}},Hr={class:"w-10 text-right pr-2 opacity-40 select-none shrink-0"},Fr={class:"w-10 text-right pr-2 opacity-40 select-none shrink-0"},Gr={class:"w-4 text-center opacity-60 select-none shrink-0"},Kr=bt({__name:"GitDiffModal",props:{path:{},data:{},loading:{type:Boolean}},emits:["close"],setup(t,{emit:e}){const n=e;return(r,o)=>t.path?(b(),v("div",{key:0,class:"fixed inset-0 z-50 flex",style:{background:"var(--p-mask-background)"},onClick:o[1]||(o[1]=Ht(a=>n("close"),["self"]))},[u("aside",Dr,[u("header",Vr,[S(f(I),{icon:"tabler:diff",class:"w-4 h-4"}),u("span",zr,y(t.path),1),u("button",{onClick:o[0]||(o[0]=a=>n("close")),class:"opacity-60 hover:opacity-100"},[S(f(I),{icon:"tabler:x",class:"w-4 h-4"})])]),t.loading?(b(),v("div",Mr,[S(f(I),{icon:"tabler:loader-2",class:"w-5 h-5 animate-spin mx-auto mb-2"}),o[2]||(o[2]=A(" Loading diff… ",-1))])):!t.data||t.data.hunks.length===0&&!t.data.diff_text?(b(),v("div",Rr," No diff (file may be untracked or identical to base). ")):(b(),v("div",Ur,[(b(!0),v(X,null,et(t.data.hunks,(a,l)=>(b(),v("div",{key:l},[u("div",Wr,y(a.header),1),(b(!0),v(X,null,et(a.lines,(s,i)=>(b(),v("pre",{key:i,class:Z(["px-0 py-0.5 flex whitespace-pre",{"bg-success-500/5 text-success-500":s.kind==="+","bg-danger-500/5 text-danger-500":s.kind==="-"}])},[o[3]||(o[3]=A("            ",-1)),u("span",Hr,y(s.old_no||""),1),o[4]||(o[4]=A(`
            `,-1)),u("span",Fr,y(s.new_no||""),1),o[5]||(o[5]=A(`
            `,-1)),u("span",Gr,y(s.kind===" "?"":s.kind),1),o[6]||(o[6]=A(`
            `,-1)),u("span",null,y(s.text),1),o[7]||(o[7]=A(`
          `,-1))],2))),128))]))),128))]))])])):V("",!0)}}),qr={class:"flex flex-col h-full"},Yr={class:"flex-1 grid grid-cols-[400px_1fr] overflow-hidden"},Xr={key:0,class:"overflow-y-auto",style:{background:"var(--p-content-background)"}},na=bt({__name:"git",setup(t){const e=Fe(),n=He(),r=Ge(),o=Ye(e,r),a=M("all"),l=M(null),s=M(!0),i=M(!1),d=M(!1);function c($,h="info"){n.toast({severity:h,summary:$,life:4e3})}Ae(async()=>{await o.refresh(),(!o.snapshot.value||(o.snapshot.value.clusters||[]).length===0)&&c("No cluster index yet — click Rebuild to build one.")}),Qt(()=>o.snapshot.value?.clusters?.length,()=>{l.value&&!o.snapshot.value?.clusters.find($=>$.id===l.value)&&(l.value=null),!l.value&&p.value.length>0&&(l.value=p.value[0].id)}),Qt(l,async $=>{if(!$){o.detail.value=null;return}try{await o.loadCluster($)}catch(h){c(rt(h)||"failed to load cluster","error")}});const p=tt(()=>{let h=(o.snapshot.value?.clusters||[]).slice();a.value==="suspect"?h=h.filter(H=>H.decision==="orphan"||H.importance==="suspect"):a.value==="pending"?h=h.filter(H=>H.decision==="pending"):a.value==="ready"?h=h.filter(H=>H.decision==="approved"):a.value==="hidden"&&(h=h.filter(H=>H.decision==="skipped"||H.decision==="split"));const U=H=>H==="pending"?0:H==="approved"?1:2;return h.sort((H,_e)=>U(H.decision)-U(_e.decision))}),g=tt(()=>o.detail.value||p.value[0]||null),x=tt(()=>g.value?.changes||[]),_=tt(()=>o.snapshot.value?.counts||{all:0,pending:0,ready:0,hidden:0,suspect:0,pushable_ready:0,blocked_ready:0}),B=tt(()=>(o.snapshot.value?.clusters||[]).length>0),L=tt(()=>(o.snapshot.value?.clusters||[]).filter($=>$.decision==="approved"&&$.pushable)),N=tt(()=>{const $=o.snapshot.value?.built_at;if(!$)return"never";const h=Math.max(0,Math.floor((Date.now()-new Date($).getTime())/6e4));return h<1?"just now":h===1?"1 min ago":h<60?h+" min ago":Math.floor(h/60)+" h ago"}),R=tt(()=>{const $=g.value?.recommendations;return $?$.some(h=>h.severity==="block"&&h.state==="open"):!1});async function z($,h){try{await o.setDecision($,h)}catch(U){c(rt(U)||"failed","error")}}async function m($,h){if(g.value)try{await o.updateRecommendation(g.value.id,$,h)}catch(U){c(rt(U)||"failed","error")}}async function j($){try{await o.rebuild({mode:$,sync_first:d.value})}catch(h){c(rt(h)||"rebuild failed","error")}}async function q(){const $=L.value.map(h=>h.id);if($.length===0){i.value=!1;return}try{const h=await o.pushApproved($);i.value=!1;const U=h.pushed+h.failed,H=h.failed>0?"error":"success";c(`Pushed ${h.pushed} of ${U} clusters`,H)}catch(h){c(rt(h)||"push failed","error")}}const nt=M(null),gt=M(null),w=M(!1);async function k($){nt.value=$,gt.value=null,w.value=!0;try{gt.value=await o.fetchDiff($)}catch(h){c(rt(h)||"diff failed","error")}finally{w.value=!1}}function C(){nt.value=null,gt.value=null}const O=M(!1),D=M("by_prefix"),Y=M([]),ot=M(!1),pt=M(!1);async function xe(){g.value&&(O.value=!0,D.value="by_prefix",await Kt())}async function Kt(){if(g.value){ot.value=!0,Y.value=[];try{const $=await o.suggestSplit(g.value.id,{mode:D.value});Y.value=$.groups||[]}catch($){c(rt($)||"split suggestion failed","error")}finally{ot.value=!1}}}function ke($){D.value=$,Kt()}async function $e(){if(!(!g.value||Y.value.length===0)){pt.value=!0;try{const $=Y.value.filter(h=>h.change_ids.length>0);if($.length<2)throw new Error("need at least 2 non-empty groups to split");await o.splitCluster(g.value.id,$),O.value=!1,c(`Split into ${$.length} clusters`,"success")}catch($){c(rt($)||"split apply failed","error")}finally{pt.value=!1}}}function we(){O.value=!1,Y.value=[]}const jt=M(null),qt=M({});async function Se($){if(g.value){jt.value=$;try{const h=await o.explainRecommendation(g.value.id,$);h.text&&(qt.value[$]=h.text)}catch(h){c(rt(h)||"explain failed","error")}finally{jt.value=null}}}return($,h)=>(b(),v("div",qr,[S(io,{stale:f(o).stale.value,rebuilding:f(o).rebuilding.value,"index-age-text":N.value,"journal-size":f(o).snapshot.value?.journal_size_at_build??null,counts:_.value,"sync-first":d.value,onRebuild:j,onPushConfirm:h[0]||(h[0]=U=>i.value=!0),"onUpdate:syncFirst":h[1]||(h[1]=U=>d.value=U)},null,8,["stale","rebuilding","index-age-text","journal-size","counts","sync-first"]),u("main",Yr,[S(So,{clusters:p.value,counts:_.value,filter:a.value,"selected-id":g.value?.id??null,loading:f(o).loading.value,error:f(o).error.value,"has-any-clusters":B.value,"onUpdate:filter":h[2]||(h[2]=U=>{a.value=U,l.value=null}),onSelect:h[3]||(h[3]=U=>l.value=U)},null,8,["clusters","counts","filter","selected-id","loading","error","has-any-clusters"]),g.value?(b(),lt(or,{key:1,cluster:g.value,changes:x.value,blocking:R.value,"pushable-ready":_.value.pushable_ready||0,"expanded-recs":s.value,explaining:jt.value,explanations:qt.value,onDecide:z,onAckRec:m,onExplainRec:Se,onOpenSplit:xe,onOpenDiff:k,onPushConfirm:h[4]||(h[4]=U=>i.value=!0),"onUpdate:expandedRecs":h[5]||(h[5]=U=>s.value=U)},null,8,["cluster","changes","blocking","pushable-ready","expanded-recs","explaining","explanations"])):(b(),v("div",Xr,[...h[7]||(h[7]=[u("div",{class:"p-12 text-center text-[12px] opacity-60"}," Pick a cluster on the left. ",-1)])]))]),S(br,{open:i.value,count:_.value.pushable_ready||0,pushing:f(o).pushing.value,clusters:L.value,onPush:q,onClose:h[6]||(h[6]=U=>i.value=!1)},null,8,["open","count","pushing","clusters"]),S(Nr,{open:O.value&&g.value!==null,title:g.value?.title??"","change-count":g.value?.change_count??0,changes:g.value?.changes??null,mode:D.value,groups:Y.value,loading:ot.value,applying:pt.value,"onUpdate:mode":ke,onApply:$e,onClose:we},null,8,["open","title","change-count","changes","mode","groups","loading","applying"]),S(Kr,{path:nt.value,data:gt.value,loading:w.value,onClose:C},null,8,["path","data","loading"])]))}});export{na as default};
//# sourceMappingURL=git-Fgi53LiW.js.map
