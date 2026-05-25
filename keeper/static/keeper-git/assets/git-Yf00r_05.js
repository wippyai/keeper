import{inject as Ft,ref as M,onUnmounted as Qt,computed as nt,useId as Oe,mergeProps as H,openBlock as b,createElementBlock as v,createElementVNode as u,renderSlot as ft,createTextVNode as T,toDisplayString as m,resolveComponent as Zt,resolveDirective as Ae,withDirectives as je,createBlock as tt,resolveDynamicComponent as ge,withCtx as Z,createCommentVNode as D,normalizeClass as J,defineComponent as bt,createVNode as S,unref as f,normalizeStyle as G,Fragment as X,renderList as ot,withModifiers as Gt,onMounted as Ie,watch as Jt}from"vue";import{A as Ee,H as Le,W as Be,m as Dt,a as vt,C as fe,s as Vt,g as ut,F as ve,N as dt,S as Q,B as W,c as he,z as Ne,b as ze,l as jt,n as De,i as te,P as Tt,Q as Ve,d as Lt,T as ee,R as ne,v as Me,e as Re,K as Ue,f as We,U as He}from"../app.js";import{Icon as I}from"@iconify/vue";import"vue-router";import"@wippy-fe/proxy";function ht(...t){if(t){let e=[];for(let n=0;n<t.length;n++){let r=t[n];if(!r)continue;let o=typeof r;if(o==="string"||o==="number")e.push(r);else if(o==="object"){let a=Array.isArray(r)?[ht(...r)]:Object.entries(r).map(([l,s])=>s?l:void 0);e=a.length?e.concat(a.filter(l=>!!l)):e}}return e.join(" ").trim()}}var Ot={};function Fe(t="pui_id_"){return Object.hasOwn(Ot,t)||(Ot[t]=0),Ot[t]++,`${t}${Ot[t]}`}function Ge(){const t=Ft(Le);if(!t)throw new Error("HostApi not provided");return t}function Ke(){const t=Ft(Ee);if(!t)throw new Error("ProxyApiInstance not provided");return t}function qe(){const t=Ft(Be);if(!t)throw new Error("WIPPY_INSTANCE not provided");return t}function Mt(t){return typeof t=="object"&&t!==null}function oe(t){return t instanceof Error?t.message:String(t)}function Ye(t){return Mt(t)&&typeof t.error=="string"?t.error:"task failed"}function Xe(t){return Mt(t)?Mt(t.data)?t.data:t:{}}function Bt(){return"req-"+Date.now().toString(36)+"-"+Math.random().toString(36).slice(2,8)}function re(t){const e={all:t.length,pending:0,ready:0,hidden:0,suspect:0,pushable_ready:0,blocked_ready:0};for(const n of t)n.decision==="pending"?e.pending+=1:n.decision==="approved"?(e.ready+=1,n.pushable?e.pushable_ready=(e.pushable_ready||0)+1:e.blocked_ready=(e.blocked_ready||0)+1):(n.decision==="skipped"||n.decision==="split"||n.decision==="pushed")&&(e.hidden+=1),(n.importance==="suspect"||n.decision==="orphan")&&(e.suspect+=1);return e}function Qe(t,e){const n=M(null),r=M(!1),o=M(!1),a=M(!1),l=M(null),s=M(null),i=18e4,d=new Map;function c(w){return new Promise((x,C)=>{const A=setTimeout(()=>{d.delete(w),C(new Error("event timeout — request_id "+w+" never arrived"))},i);d.set(w,{resolve:z=>x(z),reject:C,timer:A})})}function p(w,x,C){const A=d.get(w);A&&(clearTimeout(A.timer),d.delete(w),x?A.resolve(C):A.reject(new Error(Ye(C))))}let g=null;e&&(g=e.on("keeper.git",w=>{const x=Xe(w),C=x.event;if(typeof C!="string")return;if(C==="git.rebuild.finished"&&x.snapshot)n.value={...x.snapshot,in_progress:!1};else if(C==="git.cluster.decision_changed"&&n.value){const z=n.value.clusters.find(Y=>Y.id===x.cluster_id);z&&x.decision&&(z.decision=x.decision),n.value.counts=re(n.value.clusters)}else C==="git.index.stale"&&n.value&&(n.value.stale=!0);const A=x.request_id;A&&(C.endsWith(".finished")||C.endsWith(".failed"))&&p(A,C.endsWith(".finished"),x)})),Qt(()=>{g?.()});async function k(){r.value=!0,l.value=null;try{const{data:w}=await t.get("/api/v1/keeper/git/clusters");if(!w.success){l.value=w.error||"failed";return}n.value=w.snapshot}catch(w){l.value=oe(w)}finally{r.value=!1}}async function _(w={}){o.value=!0,l.value=null;try{const x=Bt(),C={...w,request_id:x},{data:A}=await t.post("/api/v1/keeper/git/rebuild",C);if(!A.success){l.value=A.error||"rebuild failed";return}if(n.value=A.snapshot,A.snapshot?.in_progress&&e){const z=await c(x);z?.snapshot&&(n.value={...z.snapshot,in_progress:!1})}}catch(x){l.value=oe(x)}finally{o.value=!1}}async function B(w){const{data:x}=await t.get(`/api/v1/keeper/git/clusters/${w}`);if(!x.success)throw new Error(x.error||"cluster not found");return s.value=x.cluster,x.cluster}async function L(w,x){const{data:C}=await t.patch(`/api/v1/keeper/git/clusters/${w}/decision`,{decision:x});if(!C.success)throw new Error(C.error||"set_decision failed");if(n.value){const A=n.value.clusters.find(z=>z.id===w);A&&(A.decision=x),n.value.counts=re(n.value.clusters)}s.value&&s.value.id===w&&(s.value.decision=x)}async function N(w,x,C){const{data:A}=await t.patch(`/api/v1/keeper/git/clusters/${w}/recommendations/${x}`,{state:C});if(!A.success)throw new Error(A.error||"update_recommendation failed");if(s.value&&s.value.id===w){const z=s.value.recommendations.find(Y=>Y.id===x);z&&(z.state=C)}await k()}async function R(w,x={}){const C=Bt(),{data:A}=await t.post(`/api/v1/keeper/git/clusters/${w}/suggest-split`,{...x,request_id:C});if(!A.success)throw new Error(A.error||"suggest_split failed");if(A.mode!=="ai"||A.groups)return A;if(!e)throw new Error("AI suggest requires a relay subscriber");const z=await c(C);return{...A,...z}}async function V(w,x){const{data:C}=await t.post(`/api/v1/keeper/git/clusters/${w}/split`,{groups:x});if(!C.success)throw new Error(C.error||"split failed");return n.value=C.snapshot,C.snapshot}async function y(w,x,C=!1){const A=Bt(),{data:z}=await t.post(`/api/v1/keeper/git/clusters/${w}/recommendations/${x}/explain`,{force:C,request_id:A});if(!z.success)throw new Error(z.error||"explain failed");if(z.cached||z.text){if(s.value&&s.value.id===w){const at=s.value.recommendations.find(pt=>pt.id===x);at&&(at.detail=z.text)}return z}if(!e)throw new Error("Explain requires a relay subscriber");const Y=await c(A);if(s.value&&s.value.id===w){const at=s.value.recommendations.find(pt=>pt.id===x);at&&(at.detail=Y.text)}return Y}async function j(w){const{data:x}=await t.get("/api/v1/keeper/git/diff",{params:{path:w}});if(!x.success)throw new Error(x.error||"diff failed");return{path:x.path,diff_text:x.diff_text||"",hunks:x.hunks||[],exit_code:x.exit_code}}async function q(w,x){a.value=!0;try{const{data:C}=await t.post("/api/v1/keeper/git/push",{cluster_ids:w,message:x});if(!C.success)throw new Error(C.error||"push failed");return await k(),C}finally{a.value=!1}}const rt=nt(()=>n.value?.counts.ready||0),gt=nt(()=>n.value?.stale||!1);return Qt(()=>{d.forEach(w=>clearTimeout(w.timer)),d.clear()}),{snapshot:n,loading:r,rebuilding:o,pushing:a,error:l,detail:s,readyCount:rt,stale:gt,refresh:k,rebuild:_,loadCluster:B,setDecision:L,updateRecommendation:N,explainRecommendation:y,fetchDiff:j,suggestSplit:R,splitCluster:V,pushApproved:q}}const At={critical:{dot:"var(--p-danger-500)",word:"Important"},high:{dot:"var(--p-warn-500)",word:"Worth attention"},normal:{dot:"var(--p-info-500)",word:"Routine"},cleanup:{dot:"var(--p-text-muted-color)",word:"Cleanup"},suspect:{dot:"var(--p-text-muted-color)",word:"Suspect"}},st={ready:{color:"var(--p-success-500)",bg:"color-mix(in srgb, var(--p-success-500) 7%, transparent)",border:"color-mix(in srgb, var(--p-success-500) 20%, transparent)",icon:"tabler:circle-check",phrase:"Looks ready"},closer_look:{color:"var(--p-warn-500)",bg:"color-mix(in srgb, var(--p-warn-500) 7%, transparent)",border:"color-mix(in srgb, var(--p-warn-500) 20%, transparent)",icon:"tabler:zoom-question",phrase:"Closer look"},do_not_push:{color:"var(--p-danger-500)",bg:"color-mix(in srgb, var(--p-danger-500) 7%, transparent)",border:"color-mix(in srgb, var(--p-danger-500) 20%, transparent)",icon:"tabler:hand-stop",phrase:"Don't push yet"}},Nt={info:{color:"var(--p-text-muted-color)",icon:"tabler:info-circle",bg:"transparent",label:"fyi"},warn:{color:"var(--p-warn-500)",icon:"tabler:alert-triangle",bg:"color-mix(in srgb, var(--p-warn-500) 10%, transparent)",label:"warn"},block:{color:"var(--p-danger-500)",icon:"tabler:hand-stop",bg:"color-mix(in srgb, var(--p-danger-500) 10%, transparent)",label:"block"}},zt={open:{color:"var(--p-warn-500)",bg:"color-mix(in srgb, var(--p-warn-500) 13%, transparent)",label:"open",icon:"tabler:alert-circle"},acknowledged:{color:"var(--p-info-500)",bg:"color-mix(in srgb, var(--p-info-500) 13%, transparent)",label:"acknowledged",icon:"tabler:eye-check"},fixed:{color:"var(--p-success-500)",bg:"color-mix(in srgb, var(--p-success-500) 13%, transparent)",label:"fixed",icon:"tabler:check"},split:{color:"var(--p-text-muted-color)",bg:"color-mix(in srgb, var(--p-text-muted-color) 13%, transparent)",label:"split off",icon:"tabler:arrow-split"}};function Kt(t){return t+" change"+(t===1?"":"s")}function it(t){return t instanceof Error?t.message:String(t)}var ct={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(e){return this._loadedStyleNames.has(e)},setLoadedStyleName:function(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName:function(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function Ze(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",e=Oe();return"".concat(t).concat(e.replace("v-","").replaceAll("-","_"))}var ae=W.extend({name:"common"});function kt(t){"@babel/helpers - typeof";return kt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},kt(t)}function Je(t){return ke(t)||tn(t)||me(t)||ye()}function tn(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function yt(t,e){return ke(t)||en(t,e)||me(t,e)||ye()}function ye(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function me(t,e){if(t){if(typeof t=="string")return Rt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Rt(t,e):void 0}}function Rt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function en(t,e){var n=t==null?null:typeof Symbol<"u"&&t[Symbol.iterator]||t["@@iterator"];if(n!=null){var r,o,a,l,s=[],i=!0,d=!1;try{if(a=(n=n.call(t)).next,e===0){if(Object(n)!==n)return;i=!1}else for(;!(i=(r=a.call(n)).done)&&(s.push(r.value),s.length!==e);i=!0);}catch(c){d=!0,o=c}finally{try{if(!i&&n.return!=null&&(l=n.return(),Object(l)!==l))return}finally{if(d)throw o}}return s}}function ke(t){if(Array.isArray(t))return t}function ie(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter(function(o){return Object.getOwnPropertyDescriptor(t,o).enumerable})),n.push.apply(n,r)}return n}function O(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?ie(Object(n),!0).forEach(function(r){mt(t,r,n[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):ie(Object(n)).forEach(function(r){Object.defineProperty(t,r,Object.getOwnPropertyDescriptor(n,r))})}return t}function mt(t,e,n){return(e=nn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function nn(t){var e=on(t,"string");return kt(e)=="symbol"?e:e+""}function on(t,e){if(kt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(kt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var It={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(e){dt.off("theme:change",this._loadCoreStyles),e||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(e,n){var r=this;dt.off("theme:change",this._themeScopedListener),e?(this._loadScopedThemeStyles(e),this._themeScopedListener=function(){return r._loadScopedThemeStyles(e)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var e,n,r,o,a,l,s,i,d,c,p,g=(e=this.pt)===null||e===void 0?void 0:e._usept,k=g?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,_=g?(r=this.pt)===null||r===void 0||(r=r.value)===null||r===void 0?void 0:r[this.$.type.name]:this.pt;(o=_||k)===null||o===void 0||(o=o.hooks)===null||o===void 0||(a=o.onBeforeCreate)===null||a===void 0||a.call(o);var B=(l=this.$primevueConfig)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l._usept,L=B?(s=this.$primevue)===null||s===void 0||(s=s.config)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s.originalValue:void 0,N=B?(i=this.$primevue)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.pt)===null||i===void 0?void 0:i.value:(d=this.$primevue)===null||d===void 0||(d=d.config)===null||d===void 0?void 0:d.pt;(c=N||L)===null||c===void 0||(c=c[this.$.type.name])===null||c===void 0||(c=c.hooks)===null||c===void 0||(p=c.onBeforeCreate)===null||p===void 0||p.call(c),this.$attrSelector=Ze(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var e;this.rootEl=Ne(ze(this.$el)?this.$el:(e=this.$el)===null||e===void 0?void 0:e.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=O({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(e){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(e)),r=this._useDefaultPT(this._getOptionValue,"hooks.".concat(e));n?.(),r?.()}},_mergeProps:function(e){for(var n=arguments.length,r=new Array(n>1?n-1:0),o=1;o<n;o++)r[o-1]=arguments[o];return he(e)?e.apply(void 0,r):H.apply(void 0,r)},_load:function(){ct.isStyleNameLoaded("base")||(W.loadCSS(this.$styleOptions),this._loadGlobalStyles(),ct.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var e,n;!ct.isStyleNameLoaded((e=this.$style)===null||e===void 0?void 0:e.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(ae.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),ct.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var e=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);Vt(e)&&W.load(e,O({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var e,n;if(!(this.isUnstyled||this.$theme==="none")){if(!Q.isStyleNameLoaded("common")){var r,o,a=((r=this.$style)===null||r===void 0||(o=r.getCommonTheme)===null||o===void 0?void 0:o.call(r))||{},l=a.primitive,s=a.semantic,i=a.global,d=a.style;W.load(l?.css,O({name:"primitive-variables"},this.$styleOptions)),W.load(s?.css,O({name:"semantic-variables"},this.$styleOptions)),W.load(i?.css,O({name:"global-variables"},this.$styleOptions)),W.loadStyle(O({name:"global-style"},this.$styleOptions),d),Q.setLoadedStyleName("common")}if(!Q.isStyleNameLoaded((e=this.$style)===null||e===void 0?void 0:e.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var c,p,g,k,_=((c=this.$style)===null||c===void 0||(p=c.getComponentTheme)===null||p===void 0?void 0:p.call(c))||{},B=_.css,L=_.style;(g=this.$style)===null||g===void 0||g.load(B,O({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(k=this.$style)===null||k===void 0||k.loadStyle(O({name:"".concat(this.$style.name,"-style")},this.$styleOptions),L),Q.setLoadedStyleName(this.$style.name)}if(!Q.isStyleNameLoaded("layer-order")){var N,R,V=(N=this.$style)===null||N===void 0||(R=N.getLayerOrderThemeCSS)===null||R===void 0?void 0:R.call(N);W.load(V,O({name:"layer-order",first:!0},this.$styleOptions)),Q.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(e){var n,r,o,a=((n=this.$style)===null||n===void 0||(r=n.getPresetTheme)===null||r===void 0?void 0:r.call(n,e,"[".concat(this.$attrSelector,"]")))||{},l=a.css,s=(o=this.$style)===null||o===void 0?void 0:o.load(l,O({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=s.el},_unloadScopedThemeStyles:function(){var e;(e=this.scopedStyleEl)===null||e===void 0||(e=e.value)===null||e===void 0||e.remove()},_themeChangeListener:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};ct.clearLoadedStyleNames(),dt.on("theme:change",e)},_removeThemeListeners:function(){dt.off("theme:change",this._loadCoreStyles),dt.off("theme:change",this._load),dt.off("theme:change",this._themeScopedListener)},_getHostInstance:function(e){return e?this.$options.hostName?e.$.type.name===this.$options.hostName?e:this._getHostInstance(e.$parentInstance):e.$parentInstance:void 0},_getPropValue:function(e){var n;return this[e]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[e])},_getOptionValue:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return ve(e,n,r)},_getPTValue:function(){var e,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,l=/./g.test(r)&&!!o[r.split(".")[0]],s=this._getPropValue("ptOptions")||((e=this.$primevueConfig)===null||e===void 0?void 0:e.ptOptions)||{},i=s.mergeSections,d=i===void 0?!0:i,c=s.mergeProps,p=c===void 0?!1:c,g=a?l?this._useGlobalPT(this._getPTClassValue,r,o):this._useDefaultPT(this._getPTClassValue,r,o):void 0,k=l?void 0:this._getPTSelf(n,this._getPTClassValue,r,O(O({},o),{},{global:g||{}})),_=this._getPTDatasets(r);return d||!d&&k?p?this._mergeProps(p,g,k,_):O(O(O({},g),k),_):O(O({},k),_)},_getPTSelf:function(){for(var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,r=new Array(n>1?n-1:0),o=1;o<n;o++)r[o-1]=arguments[o];return H(this._usePT.apply(this,[this._getPT(e,this.$name)].concat(r)),this._usePT.apply(this,[this.$_attrsPT].concat(r)))},_getPTDatasets:function(){var e,n,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o="data-pc-",a=r==="root"&&Vt((e=this.pt)===null||e===void 0?void 0:e["data-pc-section"]);return r!=="transition"&&O(O({},r==="root"&&O(O(mt({},"".concat(o,"name"),ut(a?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),a&&mt({},"".concat(o,"extend"),ut(this.$.type.name))),{},mt({},"".concat(this.$attrSelector),""))),{},mt({},"".concat(o,"section"),ut(r)))},_getPTClassValue:function(){var e=this._getOptionValue.apply(this,arguments);return vt(e)||fe(e)?{class:e}:e},_getPT:function(e){var n=this,r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,a=function(s){var i,d=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,c=o?o(s):s,p=ut(r),g=ut(n.$name);return(i=d?p!==g?c?.[p]:void 0:c?.[p])!==null&&i!==void 0?i:c};return e!=null&&e.hasOwnProperty("_usept")?{_usept:e._usept,originalValue:a(e.originalValue),value:a(e.value)}:a(e,!0)},_usePT:function(e,n,r,o){var a=function(B){return n(B,r,o)};if(e!=null&&e.hasOwnProperty("_usept")){var l,s=e._usept||((l=this.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},i=s.mergeSections,d=i===void 0?!0:i,c=s.mergeProps,p=c===void 0?!1:c,g=a(e.originalValue),k=a(e.value);return g===void 0&&k===void 0?void 0:vt(k)?k:vt(g)?g:d||!d&&k?p?this._mergeProps(p,g,k):O(O({},g),k):k}return a(e)},_useGlobalPT:function(e,n,r){return this._usePT(this.globalPT,e,n,r)},_useDefaultPT:function(e,n,r){return this._usePT(this.defaultPT,e,n,r)},ptm:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,e,O(O({},this.$params),n))},ptmi:function(){var e,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=H(this.$_attrsWithoutPT,this.ptm(n,r));return o?.hasOwnProperty("id")&&((e=o.id)!==null&&e!==void 0||(o.id=this.$id)),o},ptmo:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(e,n,O({instance:this},r),!1)},cx:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,e,O(O({},this.$params),n))},sx:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var o=this._getOptionValue(this.$style.inlineStyles,e,O(O({},this.$params),r)),a=this._getOptionValue(ae.inlineStyles,e,O(O({},this.$params),r));return[a,o]}}},computed:{globalPT:function(){var e,n=this;return this._getPT((e=this.$primevueConfig)===null||e===void 0?void 0:e.pt,void 0,function(r){return Dt(r,{instance:n})})},defaultPT:function(){var e,n=this;return this._getPT((e=this.$primevueConfig)===null||e===void 0?void 0:e.pt,void 0,function(r){return n._getOptionValue(r,n.$name,O({},n.$params))||Dt(r,O({},n.$params))})},isUnstyled:function(){var e;return this.unstyled!==void 0?this.unstyled:(e=this.$primevueConfig)===null||e===void 0?void 0:e.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var e,n=Object.keys(((e=this.$.vnode)===null||e===void 0?void 0:e.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(r){var o=yt(r,1),a=o[0];return n?.includes(a)}))},$theme:function(){var e;return(e=this.$primevueConfig)===null||e===void 0?void 0:e.theme},$style:function(){return O(O({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var e;return{nonce:(e=this.$primevueConfig)===null||e===void 0||(e=e.csp)===null||e===void 0?void 0:e.nonce}},$primevueConfig:function(){var e;return(e=this.$primevue)===null||e===void 0?void 0:e.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var e=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:e,props:e?.$props,state:e?.$data,attrs:e?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(e){var n=yt(e,1),r=n[0];return r?.startsWith("pt:")}).reduce(function(e,n){var r=yt(n,2),o=r[0],a=r[1],l=o.split(":"),s=Je(l),i=Rt(s).slice(1);return i?.reduce(function(d,c,p,g){return!d[c]&&(d[c]=p===g.length-1?a:{}),d[c]},e),e},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(e){var n=yt(e,1),r=n[0];return!(r!=null&&r.startsWith("pt:"))}).reduce(function(e,n){var r=yt(n,2),o=r[0],a=r[1];return e[o]=a,e},{})}}},rn=`
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
`,an=W.extend({name:"baseicon",css:rn});function xt(t){"@babel/helpers - typeof";return xt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},xt(t)}function se(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter(function(o){return Object.getOwnPropertyDescriptor(t,o).enumerable})),n.push.apply(n,r)}return n}function le(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?se(Object(n),!0).forEach(function(r){sn(t,r,n[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):se(Object(n)).forEach(function(r){Object.defineProperty(t,r,Object.getOwnPropertyDescriptor(n,r))})}return t}function sn(t,e,n){return(e=ln(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function ln(t){var e=dn(t,"string");return xt(e)=="symbol"?e:e+""}function dn(t,e){if(xt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(xt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var un={name:"BaseIcon",extends:It,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:an,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var e=jt(this.label);return le(le({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:e?void 0:"img","aria-label":e?void 0:this.label,"aria-hidden":e})}}},xe={name:"SpinnerIcon",extends:un};function cn(t){return fn(t)||gn(t)||bn(t)||pn()}function pn(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function bn(t,e){if(t){if(typeof t=="string")return Ut(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Ut(t,e):void 0}}function gn(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function fn(t){if(Array.isArray(t))return Ut(t)}function Ut(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function vn(t,e,n,r,o,a){return b(),v("svg",H({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),cn(e[0]||(e[0]=[u("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}xe.render=vn;var hn=`
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
`,yn={root:function(e){var n=e.props,r=e.instance;return["p-badge p-component",{"p-badge-circle":Vt(n.value)&&String(n.value).length===1,"p-badge-dot":jt(n.value)&&!r.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},mn=W.extend({name:"badge",style:hn,classes:yn}),kn={name:"BaseBadge",extends:It,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:mn,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function $t(t){"@babel/helpers - typeof";return $t=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},$t(t)}function de(t,e,n){return(e=xn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function xn(t){var e=$n(t,"string");return $t(e)=="symbol"?e:e+""}function $n(t,e){if($t(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if($t(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var $e={name:"Badge",extends:kn,inheritAttrs:!1,computed:{dataP:function(){return ht(de(de({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},wn=["data-p"];function Sn(t,e,n,r,o,a){return b(),v("span",H({class:t.cx("root"),"data-p":a.dataP},t.ptmi("root")),[ft(t.$slots,"default",{},function(){return[T(m(t.value),1)]})],16,wn)}$e.render=Sn;function wt(t){"@babel/helpers - typeof";return wt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},wt(t)}function ue(t,e){return Tn(t)||Cn(t,e)||Pn(t,e)||_n()}function _n(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Pn(t,e){if(t){if(typeof t=="string")return ce(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ce(t,e):void 0}}function ce(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function Cn(t,e){var n=t==null?null:typeof Symbol<"u"&&t[Symbol.iterator]||t["@@iterator"];if(n!=null){var r,o,a,l,s=[],i=!0,d=!1;try{if(a=(n=n.call(t)).next,e!==0)for(;!(i=(r=a.call(n)).done)&&(s.push(r.value),s.length!==e);i=!0);}catch(c){d=!0,o=c}finally{try{if(!i&&n.return!=null&&(l=n.return(),Object(l)!==l))return}finally{if(d)throw o}}return s}}function Tn(t){if(Array.isArray(t))return t}function pe(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter(function(o){return Object.getOwnPropertyDescriptor(t,o).enumerable})),n.push.apply(n,r)}return n}function E(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?pe(Object(n),!0).forEach(function(r){Wt(t,r,n[r])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):pe(Object(n)).forEach(function(r){Object.defineProperty(t,r,Object.getOwnPropertyDescriptor(n,r))})}return t}function Wt(t,e,n){return(e=On(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function On(t){var e=An(t,"string");return wt(e)=="symbol"?e:e+""}function An(t,e){if(wt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(wt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var P={_getMeta:function(){return[te(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],Dt(te(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(e,n){var r,o,a;return(r=(e==null||(o=e.instance)===null||o===void 0?void 0:o.$primevue)||(n==null||(a=n.ctx)===null||a===void 0||(a=a.appContext)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.globalProperties)===null||a===void 0?void 0:a.$primevue))===null||r===void 0?void 0:r.config},_getOptionValue:ve,_getPTValue:function(){var e,n,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},a=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",l=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},s=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,i=function(){var R=P._getOptionValue.apply(P,arguments);return vt(R)||fe(R)?{class:R}:R},d=((e=r.binding)===null||e===void 0||(e=e.value)===null||e===void 0?void 0:e.ptOptions)||((n=r.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},c=d.mergeSections,p=c===void 0?!0:c,g=d.mergeProps,k=g===void 0?!1:g,_=s?P._useDefaultPT(r,r.defaultPT(),i,a,l):void 0,B=P._usePT(r,P._getPT(o,r.$name),i,a,E(E({},l),{},{global:_||{}})),L=P._getPTDatasets(r,a);return p||!p&&B?k?P._mergeProps(r,k,_,B,L):E(E(E({},_),B),L):E(E({},B),L)},_getPTDatasets:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r="data-pc-";return E(E({},n==="root"&&Wt({},"".concat(r,"name"),ut(e.$name))),{},Wt({},"".concat(r,"section"),ut(n)))},_getPT:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,o=function(l){var s,i=r?r(l):l,d=ut(n);return(s=i?.[d])!==null&&s!==void 0?s:i};return e&&Object.hasOwn(e,"_usept")?{_usept:e._usept,originalValue:o(e.originalValue),value:o(e.value)}:o(e)},_usePT:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,o=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0,l=function(L){return r(L,o,a)};if(n&&Object.hasOwn(n,"_usept")){var s,i=n._usept||((s=e.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},d=i.mergeSections,c=d===void 0?!0:d,p=i.mergeProps,g=p===void 0?!1:p,k=l(n.originalValue),_=l(n.value);return k===void 0&&_===void 0?void 0:vt(_)?_:vt(k)?k:c||!c&&_?g?P._mergeProps(e,g,k,_):E(E({},k),_):_}return l(n)},_useDefaultPT:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=arguments.length>2?arguments[2]:void 0,o=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0;return P._usePT(e,n,r,o,a)},_loadStyles:function(){var e,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,a=P._getConfig(r,o),l={nonce:a==null||(e=a.csp)===null||e===void 0?void 0:e.nonce};P._loadCoreStyles(n,l),P._loadThemeStyles(n,l),P._loadScopedThemeStyles(n,l),P._removeThemeListeners(n),n.$loadStyles=function(){return P._loadThemeStyles(n,l)},P._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var e,n,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0;if(!ct.isStyleNameLoaded((e=r.$style)===null||e===void 0?void 0:e.name)&&(n=r.$style)!==null&&n!==void 0&&n.name){var a;W.loadCSS(o),(a=r.$style)===null||a===void 0||a.loadCSS(o),ct.setLoadedStyleName(r.$style.name)}},_loadThemeStyles:function(){var e,n,r,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},a=arguments.length>1?arguments[1]:void 0;if(!(o!=null&&o.isUnstyled()||(o==null||(e=o.theme)===null||e===void 0?void 0:e.call(o))==="none")){if(!Q.isStyleNameLoaded("common")){var l,s,i=((l=o.$style)===null||l===void 0||(s=l.getCommonTheme)===null||s===void 0?void 0:s.call(l))||{},d=i.primitive,c=i.semantic,p=i.global,g=i.style;W.load(d?.css,E({name:"primitive-variables"},a)),W.load(c?.css,E({name:"semantic-variables"},a)),W.load(p?.css,E({name:"global-variables"},a)),W.loadStyle(E({name:"global-style"},a),g),Q.setLoadedStyleName("common")}if(!Q.isStyleNameLoaded((n=o.$style)===null||n===void 0?void 0:n.name)&&(r=o.$style)!==null&&r!==void 0&&r.name){var k,_,B,L,N=((k=o.$style)===null||k===void 0||(_=k.getDirectiveTheme)===null||_===void 0?void 0:_.call(k))||{},R=N.css,V=N.style;(B=o.$style)===null||B===void 0||B.load(R,E({name:"".concat(o.$style.name,"-variables")},a)),(L=o.$style)===null||L===void 0||L.loadStyle(E({name:"".concat(o.$style.name,"-style")},a),V),Q.setLoadedStyleName(o.$style.name)}if(!Q.isStyleNameLoaded("layer-order")){var y,j,q=(y=o.$style)===null||y===void 0||(j=y.getLayerOrderThemeCSS)===null||j===void 0?void 0:j.call(y);W.load(q,E({name:"layer-order",first:!0},a)),Q.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,r=e.preset();if(r&&e.$attrSelector){var o,a,l,s=((o=e.$style)===null||o===void 0||(a=o.getPresetTheme)===null||a===void 0?void 0:a.call(o,r,"[".concat(e.$attrSelector,"]")))||{},i=s.css,d=(l=e.$style)===null||l===void 0?void 0:l.load(i,E({name:"".concat(e.$attrSelector,"-").concat(e.$style.name)},n));e.scopedStyleEl=d.el}},_themeChangeListener:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};ct.clearLoadedStyleNames(),dt.on("theme:change",e)},_removeThemeListeners:function(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};dt.off("theme:change",e.$loadStyles),e.$loadStyles=void 0},_hook:function(e,n,r,o,a,l){var s,i,d="on".concat(De(n)),c=P._getConfig(o,a),p=r?.$instance,g=P._usePT(p,P._getPT(o==null||(s=o.value)===null||s===void 0?void 0:s.pt,e),P._getOptionValue,"hooks.".concat(d)),k=P._useDefaultPT(p,c==null||(i=c.pt)===null||i===void 0||(i=i.directives)===null||i===void 0?void 0:i[e],P._getOptionValue,"hooks.".concat(d)),_={el:r,binding:o,vnode:a,prevVnode:l};g?.(p,_),k?.(p,_)},_mergeProps:function(){for(var e=arguments.length>1?arguments[1]:void 0,n=arguments.length,r=new Array(n>2?n-2:0),o=2;o<n;o++)r[o-2]=arguments[o];return he(e)?e.apply(void 0,r):H.apply(void 0,r)},_extend:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=function(s,i,d,c,p){var g,k,_,B;i._$instances=i._$instances||{};var L=P._getConfig(d,c),N=i._$instances[e]||{},R=jt(N)?E(E({},n),n?.methods):{};i._$instances[e]=E(E({},N),{},{$name:e,$host:i,$binding:d,$modifiers:d?.modifiers,$value:d?.value,$el:N.$el||i||void 0,$style:E({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:L,$attrSelector:(g=i.$pd)===null||g===void 0||(g=g[e])===null||g===void 0?void 0:g.attrSelector,defaultPT:function(){return P._getPT(L?.pt,void 0,function(y){var j;return y==null||(j=y.directives)===null||j===void 0?void 0:j[e]})},isUnstyled:function(){var y,j;return((y=i._$instances[e])===null||y===void 0||(y=y.$binding)===null||y===void 0||(y=y.value)===null||y===void 0?void 0:y.unstyled)!==void 0?(j=i._$instances[e])===null||j===void 0||(j=j.$binding)===null||j===void 0||(j=j.value)===null||j===void 0?void 0:j.unstyled:L?.unstyled},theme:function(){var y;return(y=i._$instances[e])===null||y===void 0||(y=y.$primevueConfig)===null||y===void 0?void 0:y.theme},preset:function(){var y;return(y=i._$instances[e])===null||y===void 0||(y=y.$binding)===null||y===void 0||(y=y.value)===null||y===void 0?void 0:y.dt},ptm:function(){var y,j=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",q=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return P._getPTValue(i._$instances[e],(y=i._$instances[e])===null||y===void 0||(y=y.$binding)===null||y===void 0||(y=y.value)===null||y===void 0?void 0:y.pt,j,E({},q))},ptmo:function(){var y=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},j=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",q=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return P._getPTValue(i._$instances[e],y,j,q,!1)},cx:function(){var y,j,q=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",rt=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(y=i._$instances[e])!==null&&y!==void 0&&y.isUnstyled()?void 0:P._getOptionValue((j=i._$instances[e])===null||j===void 0||(j=j.$style)===null||j===void 0?void 0:j.classes,q,E({},rt))},sx:function(){var y,j=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",q=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,rt=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return q?P._getOptionValue((y=i._$instances[e])===null||y===void 0||(y=y.$style)===null||y===void 0?void 0:y.inlineStyles,j,E({},rt)):void 0}},R),i.$instance=i._$instances[e],(k=(_=i.$instance)[s])===null||k===void 0||k.call(_,i,d,c,p),i["$".concat(e)]=i.$instance,P._hook(e,s,i,d,c,p),i.$pd||(i.$pd={}),i.$pd[e]=E(E({},(B=i.$pd)===null||B===void 0?void 0:B[e]),{},{name:e,instance:i._$instances[e]})},o=function(s){var i,d,c,p=s._$instances[e],g=p?.watch,k=function(L){var N,R=L.newValue,V=L.oldValue;return g==null||(N=g.config)===null||N===void 0?void 0:N.call(p,R,V)},_=function(L){var N,R=L.newValue,V=L.oldValue;return g==null||(N=g["config.ripple"])===null||N===void 0?void 0:N.call(p,R,V)};p.$watchersCallback={config:k,"config.ripple":_},g==null||(i=g.config)===null||i===void 0||i.call(p,p?.$primevueConfig),Tt.on("config:change",k),g==null||(d=g["config.ripple"])===null||d===void 0||d.call(p,p==null||(c=p.$primevueConfig)===null||c===void 0?void 0:c.ripple),Tt.on("config:ripple:change",_)},a=function(s){var i=s._$instances[e].$watchersCallback;i&&(Tt.off("config:change",i.config),Tt.off("config:ripple:change",i["config.ripple"]),s._$instances[e].$watchersCallback=void 0)};return{created:function(s,i,d,c){s.$pd||(s.$pd={}),s.$pd[e]={name:e,attrSelector:Fe("pd")},r("created",s,i,d,c)},beforeMount:function(s,i,d,c){var p;P._loadStyles((p=s.$pd[e])===null||p===void 0?void 0:p.instance,i,d),r("beforeMount",s,i,d,c),o(s)},mounted:function(s,i,d,c){var p;P._loadStyles((p=s.$pd[e])===null||p===void 0?void 0:p.instance,i,d),r("mounted",s,i,d,c)},beforeUpdate:function(s,i,d,c){r("beforeUpdate",s,i,d,c)},updated:function(s,i,d,c){var p;P._loadStyles((p=s.$pd[e])===null||p===void 0?void 0:p.instance,i,d),r("updated",s,i,d,c)},beforeUnmount:function(s,i,d,c){var p;a(s),P._removeThemeListeners((p=s.$pd[e])===null||p===void 0?void 0:p.instance),r("beforeUnmount",s,i,d,c)},unmounted:function(s,i,d,c){var p;(p=s.$pd[e])===null||p===void 0||(p=p.instance)===null||p===void 0||(p=p.scopedStyleEl)===null||p===void 0||(p=p.value)===null||p===void 0||p.remove(),r("unmounted",s,i,d,c)}}},extend:function(){var e=P._getMeta.apply(P,arguments),n=ue(e,2),r=n[0],o=n[1];return E({extend:function(){var l=P._getMeta.apply(P,arguments),s=ue(l,2),i=s[0],d=s[1];return P.extend(i,E(E(E({},o),o?.methods),d))}},P._extend(r,o))}},jn=`
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
`,In={root:"p-ink"},En=W.extend({name:"ripple-directive",style:jn,classes:In}),Ln=P.extend({style:En});function St(t){"@babel/helpers - typeof";return St=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},St(t)}function Bn(t){return Vn(t)||Dn(t)||zn(t)||Nn()}function Nn(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function zn(t,e){if(t){if(typeof t=="string")return Ht(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Ht(t,e):void 0}}function Dn(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function Vn(t){if(Array.isArray(t))return Ht(t)}function Ht(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,r=Array(e);n<e;n++)r[n]=t[n];return r}function be(t,e,n){return(e=Mn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Mn(t){var e=Rn(t,"string");return St(e)=="symbol"?e:e+""}function Rn(t,e){if(St(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(St(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Un=Ln.extend("ripple",{watch:{"config.ripple":function(e){e?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(e){this.remove(e)},timeout:void 0,methods:{bindEvents:function(e){e.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(e){e.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(e){var n=this.getInk(e);n||(n=He("span",be(be({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),e.appendChild(n),this.$el=n)},remove:function(e){var n=this.getInk(e);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(e),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(e){var n=this,r=e.currentTarget,o=this.getInk(r);if(!(!o||getComputedStyle(o,null).display==="none")){if(!this.isUnstyled()&&Lt(o,"p-ink-active"),o.setAttribute("data-p-ink-active","false"),!ee(o)&&!ne(o)){var a=Math.max(Me(r),Re(r));o.style.height=a+"px",o.style.width=a+"px"}var l=Ue(r),s=e.pageX-l.left+document.body.scrollTop-ne(o)/2,i=e.pageY-l.top+document.body.scrollLeft-ee(o)/2;o.style.top=i+"px",o.style.left=s+"px",!this.isUnstyled()&&We(o,"p-ink-active"),o.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){o&&(!n.isUnstyled()&&Lt(o,"p-ink-active"),o.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(e){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&Lt(e.currentTarget,"p-ink-active"),e.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(e){return e&&e.children?Bn(e.children).find(function(n){return Ve(n,"data-pc-name")==="ripple"}):void 0}}}),Wn=`
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
`;function _t(t){"@babel/helpers - typeof";return _t=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},_t(t)}function et(t,e,n){return(e=Hn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Hn(t){var e=Fn(t,"string");return _t(e)=="symbol"?e:e+""}function Fn(t,e){if(_t(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(_t(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Gn={root:function(e){var n=e.instance,r=e.props;return["p-button p-component",et(et(et(et(et(et(et(et(et({"p-button-icon-only":n.hasIcon&&!r.label&&!r.badge,"p-button-vertical":(r.iconPos==="top"||r.iconPos==="bottom")&&r.label,"p-button-loading":r.loading,"p-button-link":r.link||r.variant==="link"},"p-button-".concat(r.severity),r.severity),"p-button-raised",r.raised),"p-button-rounded",r.rounded),"p-button-text",r.text||r.variant==="text"),"p-button-outlined",r.outlined||r.variant==="outlined"),"p-button-sm",r.size==="small"),"p-button-lg",r.size==="large"),"p-button-plain",r.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(e){var n=e.props;return["p-button-icon",et({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},Kn=W.extend({name:"button",style:Wn,classes:Gn}),qn={name:"BaseButton",extends:It,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:Kn,provide:function(){return{$pcButton:this,$parentInstance:this}}};function Pt(t){"@babel/helpers - typeof";return Pt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Pt(t)}function K(t,e,n){return(e=Yn(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Yn(t){var e=Xn(t,"string");return Pt(e)=="symbol"?e:e+""}function Xn(t,e){if(Pt(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(Pt(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var lt={name:"Button",extends:qn,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(e){var n=e==="root"?this.ptmi:this.ptm;return n(e,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return H(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return jt(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return ht(K(K(K(K(K(K(K(K(K(K({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return ht(K(K({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return ht(K(K({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:xe,Badge:$e},directives:{ripple:Un}},Qn=["data-p"],Zn=["data-p"];function Jn(t,e,n,r,o,a){var l=Zt("SpinnerIcon"),s=Zt("Badge"),i=Ae("ripple");return t.asChild?ft(t.$slots,"default",{key:1,class:J(t.cx("root")),a11yAttrs:a.a11yAttrs}):je((b(),tt(ge(t.as),H({key:0,class:t.cx("root"),"data-p":a.dataP},a.attrs),{default:Z(function(){return[ft(t.$slots,"default",{},function(){return[t.loading?ft(t.$slots,"loadingicon",H({key:0,class:[t.cx("loadingIcon"),t.cx("icon")]},t.ptm("loadingIcon")),function(){return[t.loadingIcon?(b(),v("span",H({key:0,class:[t.cx("loadingIcon"),t.cx("icon"),t.loadingIcon]},t.ptm("loadingIcon")),null,16)):(b(),tt(l,H({key:1,class:[t.cx("loadingIcon"),t.cx("icon")],spin:""},t.ptm("loadingIcon")),null,16,["class"]))]}):ft(t.$slots,"icon",H({key:1,class:[t.cx("icon")]},t.ptm("icon")),function(){return[t.icon?(b(),v("span",H({key:0,class:[t.cx("icon"),t.icon,t.iconClass],"data-p":a.dataIconP},t.ptm("icon")),null,16,Qn)):D("",!0)]}),t.label?(b(),v("span",H({key:2,class:t.cx("label")},t.ptm("label"),{"data-p":a.dataLabelP}),m(t.label),17,Zn)):D("",!0),t.badge?(b(),tt(s,{key:3,value:t.badge,class:J(t.badgeClass),severity:t.badgeSeverity,unstyled:t.unstyled,pt:t.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):D("",!0)]})]}),_:3},16,["class","data-p"])),[[i]])}lt.render=Jn;const to={class:"px-5 py-2.5 border-b flex items-center gap-3 text-[12px]",style:{"border-color":"var(--p-content-border-color)"}},eo=["disabled"],no=["disabled"],oo={class:"flex items-center gap-1 cursor-pointer text-[10px] opacity-70 hover:opacity-100",title:"Sync registry overlays to disk before scanning git"},ro=["checked"],ao={class:"opacity-70"},io={key:1,class:"ml-auto opacity-60 text-[11px]"},so={key:2,class:"ml-auto opacity-50 text-[11px]"},lo=bt({__name:"GitHeader",props:{stale:{type:Boolean},rebuilding:{type:Boolean},indexAgeText:{},journalSize:{},counts:{},syncFirst:{type:Boolean}},emits:["rebuild","push-confirm","update:syncFirst"],setup(t,{emit:e}){const n=e;return(r,o)=>(b(),v("header",to,[S(f(I),{icon:"tabler:git-pull-request",class:"w-4 h-4"}),o[6]||(o[6]=u("h1",{class:"text-[13px] font-semibold"},"Git",-1)),o[7]||(o[7]=u("span",{class:"opacity-50"},"·",-1)),u("div",{class:J(["flex items-center gap-2 px-2 py-1 rounded",{"bg-warn-500/10":t.stale}]),style:G(t.stale?{}:{background:"var(--p-content-hover-background)"})},[S(f(I),{icon:t.stale?"tabler:alert-triangle":"tabler:database",class:J(["w-3.5 h-3.5",{"text-warn-500":t.stale}])},null,8,["icon","class"]),u("span",{class:J(["text-[11px]",{"text-warn-500":t.stale}])},[T(" Index built "+m(t.indexAgeText)+" ",1),t.journalSize!==null?(b(),v(X,{key:0},[T(" · "+m(t.journalSize)+" changes ",1)],64)):D("",!0)],2),u("button",{onClick:o[0]||(o[0]=a=>n("rebuild","ai")),disabled:t.rebuilding,class:J(["text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1 text-white",{"bg-warn-500":t.stale}]),style:G(t.stale?{}:{background:"var(--p-primary-color)"}),title:"AI-clustered rebuild — groups changes by topic via Sonnet (~30-90s)"},[S(f(I),{icon:t.rebuilding?"tabler:loader-2":"tabler:sparkles",class:J(t.rebuilding?"w-3 h-3 animate-spin":"w-3 h-3")},null,8,["icon","class"]),T(" "+m(t.rebuilding?"Rebuilding…":"AI rebuild"),1)],14,eo),u("button",{onClick:o[1]||(o[1]=a=>n("rebuild","manual")),disabled:t.rebuilding,class:"text-[11px] px-2 py-0.5 rounded font-medium flex items-center gap-1",style:{background:"var(--kp-btn-secondary-bg)"},title:"Manual rebuild — group by directory prefix (no LLM, instant)"},[S(f(I),{icon:"tabler:list",class:"w-3 h-3"}),o[4]||(o[4]=T(" Manual ",-1))],8,no),u("label",oo,[u("input",{type:"checkbox",checked:t.syncFirst,onChange:o[2]||(o[2]=a=>n("update:syncFirst",a.target.checked)),class:"w-3 h-3"},null,40,ro),o[5]||(o[5]=T(" sync first ",-1))])],6),o[8]||(o[8]=u("span",{class:"opacity-50"},"·",-1)),u("span",ao,m(t.counts.all)+" clusters · "+m(t.counts.suspect)+" suspect",1),(t.counts.pushable_ready||0)>0?(b(),tt(f(lt),{key:0,onClick:o[3]||(o[3]=a=>n("push-confirm")),severity:"success",class:"ml-auto !px-3 !py-1 !text-[11px] !font-semibold !gap-1.5"},{default:Z(()=>[S(f(I),{icon:"tabler:upload",class:"w-3.5 h-3.5"}),T(" Push "+m(t.counts.pushable_ready)+" ready ",1)]),_:1})):(t.counts.blocked_ready||0)>0?(b(),v("span",io,m(t.counts.blocked_ready)+" ready for review only ",1)):(b(),v("span",so," Mark clusters ready to enable push "))]))}});var uo=`
    .p-tag {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        background: dt('tag.primary.background');
        color: dt('tag.primary.color');
        font-size: dt('tag.font.size');
        font-weight: dt('tag.font.weight');
        padding: dt('tag.padding');
        border-radius: dt('tag.border.radius');
        gap: dt('tag.gap');
    }

    .p-tag-icon {
        font-size: dt('tag.icon.size');
        width: dt('tag.icon.size');
        height: dt('tag.icon.size');
    }

    .p-tag-rounded {
        border-radius: dt('tag.rounded.border.radius');
    }

    .p-tag-success {
        background: dt('tag.success.background');
        color: dt('tag.success.color');
    }

    .p-tag-info {
        background: dt('tag.info.background');
        color: dt('tag.info.color');
    }

    .p-tag-warn {
        background: dt('tag.warn.background');
        color: dt('tag.warn.color');
    }

    .p-tag-danger {
        background: dt('tag.danger.background');
        color: dt('tag.danger.color');
    }

    .p-tag-secondary {
        background: dt('tag.secondary.background');
        color: dt('tag.secondary.color');
    }

    .p-tag-contrast {
        background: dt('tag.contrast.background');
        color: dt('tag.contrast.color');
    }
`,co={root:function(e){var n=e.props;return["p-tag p-component",{"p-tag-info":n.severity==="info","p-tag-success":n.severity==="success","p-tag-warn":n.severity==="warn","p-tag-danger":n.severity==="danger","p-tag-secondary":n.severity==="secondary","p-tag-contrast":n.severity==="contrast","p-tag-rounded":n.rounded}]},icon:"p-tag-icon",label:"p-tag-label"},po=W.extend({name:"tag",style:uo,classes:co}),bo={name:"BaseTag",extends:It,props:{value:null,severity:null,rounded:Boolean,icon:String},style:po,provide:function(){return{$pcTag:this,$parentInstance:this}}};function Ct(t){"@babel/helpers - typeof";return Ct=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Ct(t)}function go(t,e,n){return(e=fo(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function fo(t){var e=vo(t,"string");return Ct(e)=="symbol"?e:e+""}function vo(t,e){if(Ct(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var r=n.call(t,e);if(Ct(r)!="object")return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var qt={name:"Tag",extends:bo,inheritAttrs:!1,computed:{dataP:function(){return ht(go({rounded:this.rounded},this.severity,this.severity))}}},ho=["data-p"];function yo(t,e,n,r,o,a){return b(),v("span",H({class:t.cx("root"),"data-p":a.dataP},t.ptmi("root")),[t.$slots.icon?(b(),tt(ge(t.$slots.icon),H({key:0,class:t.cx("icon")},t.ptm("icon")),null,16,["class"])):t.icon?(b(),v("span",H({key:1,class:[t.cx("icon"),t.icon]},t.ptm("icon")),null,16)):D("",!0),t.value!=null||t.$slots.default?ft(t.$slots,"default",{key:2},function(){return[u("span",H({class:t.cx("label")},t.ptm("label")),m(t.value),17)]}):D("",!0)],16,ho)}qt.render=yo;const mo={class:"flex flex-col"},ko={class:"px-5 py-2 border-b flex items-center gap-1 text-[10px]",style:{"border-color":"var(--p-content-border-color)"}},xo=["onClick"],$o={class:"opacity-80"},wo={class:"flex-1 overflow-y-auto border-r",style:{"border-color":"var(--p-content-border-color)"}},So={key:0,class:"p-8 text-center text-[12px] opacity-60"},_o={key:1,class:"p-6 text-[12px] text-danger-500"},Po={key:2,class:"p-12 text-center text-[12px] opacity-60"},Co={key:0},To={key:1},Oo=["onClick"],Ao={class:"flex items-center gap-2 mb-1.5"},jo={class:"text-[12px] font-semibold flex-1 truncate"},Io={class:"flex items-center gap-2 text-[10px] opacity-70 mb-1"},Eo={class:"text-[10px] opacity-70 leading-snug truncate"},Lo=bt({__name:"GitClusterList",props:{clusters:{},counts:{},filter:{},selectedId:{},loading:{type:Boolean},error:{},hasAnyClusters:{type:Boolean}},emits:["update:filter","select"],setup(t,{emit:e}){const n=e,r=[{key:"all",label:"All"},{key:"pending",label:"Pending"},{key:"ready",label:"Ready to push"},{key:"hidden",label:"Hidden"},{key:"suspect",label:"Suspect"}];return(o,a)=>(b(),v("div",mo,[u("div",ko,[(b(),v(X,null,ot(r,l=>u("button",{key:l.key,onClick:s=>n("update:filter",l.key),class:"px-1.5 py-0.5 rounded font-medium flex items-center gap-1 transition",style:G({background:t.filter===l.key?"var(--p-primary-color)":"var(--p-content-hover-background)",color:t.filter===l.key?"var(--p-primary-contrast-color)":"inherit"})},[T(m(l.label)+" ",1),u("span",$o,m(t.counts[l.key]),1)],12,xo)),64))]),u("section",wo,[t.loading&&!t.hasAnyClusters?(b(),v("div",So," Loading… ")):t.error?(b(),v("div",_o,m(t.error),1)):t.clusters.length===0?(b(),v("div",Po,[t.hasAnyClusters?(b(),v("span",To,"Nothing matches.")):(b(),v("span",Co," No cluster index yet. Click Rebuild above to build one. "))])):D("",!0),(b(!0),v(X,null,ot(t.clusters,l=>(b(),v("article",{key:l.id,onClick:s=>n("select",l.id),class:"px-4 py-3 border-b cursor-pointer transition",style:G({borderColor:"var(--p-content-border-color)",background:t.selectedId===l.id?"var(--p-content-hover-background)":"transparent",opacity:l.decision!=="pending"?.65:1})},[u("div",Ao,[u("span",{class:"w-2 h-2 rounded-full shrink-0",style:G({background:f(At)[l.importance].dot})},null,4),u("h3",jo,m(l.title),1),l.decision==="approved"?(b(),tt(f(I),{key:0,icon:"tabler:circle-check",class:"w-3.5 h-3.5 shrink-0 text-success-500"})):l.decision==="split"?(b(),tt(f(I),{key:1,icon:"tabler:arrow-split",class:"w-3.5 h-3.5 shrink-0 opacity-50"})):l.decision==="skipped"?(b(),tt(f(I),{key:2,icon:"tabler:archive",class:"w-3.5 h-3.5 shrink-0 opacity-50"})):D("",!0)]),u("div",Io,[u("span",null,m(f(Kt)(l.change_count)),1),a[0]||(a[0]=u("span",{class:"opacity-50"},"·",-1)),u("span",{class:"flex items-center gap-1",style:G({color:f(st)[l.verdict].color})},[S(f(I),{icon:f(st)[l.verdict].icon,class:"w-3 h-3"},null,8,["icon"]),T(" "+m(f(st)[l.verdict].phrase),1)],4),l.rec_open>0?(b(),tt(f(qt),{key:0,severity:"warn",class:"ml-auto !text-[9px] !px-1 !py-0"},{default:Z(()=>[T(m(l.rec_open)+" open ",1)]),_:2},1024)):D("",!0)]),u("p",Eo,m(l.plain_summary),1)],12,Oo))),128))])]))}}),Bo={class:"overflow-y-auto",style:{background:"var(--p-content-background)"}},No={class:"p-6"},zo={class:"flex items-center gap-2 mb-2"},Do={class:"text-[11px] opacity-70"},Vo={class:"text-[11px] opacity-70"},Mo={key:0,class:"text-[11px] opacity-50"},Ro={key:1,class:"text-[11px] opacity-70"},Uo={class:"ml-auto text-[10px] opacity-50 font-mono"},Wo={class:"text-[20px] font-semibold mb-2"},Ho={class:"text-[13px] opacity-85 leading-relaxed mb-4"},Fo={class:"text-[11px] opacity-80"},Go={key:0,class:"mb-5"},Ko={class:"text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5"},qo={key:0,class:"space-y-1.5"},Yo={class:"flex-1 min-w-0"},Xo={class:"text-[12px]"},Qo={key:0,class:"text-[11px] opacity-70 mt-0.5"},Zo={key:1,class:"flex gap-1 mt-2 flex-wrap"},Jo={key:2,class:"mt-2 p-2.5 rounded text-[11px] leading-relaxed whitespace-pre-wrap border-l-[3px] border-accent-500",style:{background:"var(--p-content-hover-background)"}},tr={class:"text-[9px] uppercase tracking-wide opacity-60 mb-1 flex items-center gap-1"},er={key:1,class:"mb-5"},nr={class:"text-[10px] font-semibold uppercase tracking-wide opacity-60 mb-2 flex items-center gap-1.5"},or={class:"rounded border",style:{"border-color":"var(--p-content-border-color)"}},rr=["onClick"],ar={class:"font-mono text-[11px] flex-1 truncate"},ir={key:0,class:"text-[10px] shrink-0 text-success-500"},sr={key:1,class:"text-[10px] shrink-0 text-danger-500"},lr={key:0,class:"px-3 py-1.5 text-[10px] opacity-60"},dr={class:"sticky bottom-0 -mx-6 px-6 py-3 border-t flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)",background:"var(--p-content-background)"}},ur={key:0,class:"text-[11px] ml-2 text-danger-500"},cr={class:"text-[11px] flex items-center gap-1.5 text-success-500"},pr={key:1,class:"ml-auto text-[11px] opacity-60"},br=bt({__name:"GitClusterDetail",props:{cluster:{},changes:{},blocking:{type:Boolean},pushableReady:{},expandedRecs:{type:Boolean},explaining:{},explanations:{}},emits:["decide","ack-rec","explain-rec","open-split","open-diff","push-confirm","update:expandedRecs"],setup(t,{emit:e}){const n=e;return(r,o)=>(b(),v("section",Bo,[u("article",No,[u("div",zo,[u("span",{class:"w-2 h-2 rounded-full",style:G({background:f(At)[t.cluster.importance].dot})},null,4),u("span",Do,m(f(At)[t.cluster.importance].word),1),o[7]||(o[7]=u("span",{class:"text-[11px] opacity-50"},"·",-1)),u("span",Vo,m(f(Kt)(t.cluster.change_count)),1),t.cluster.stats?(b(),v("span",Mo,"·")):D("",!0),t.cluster.stats?(b(),v("span",Ro,m(t.cluster.stats.namespaces?.length||0)+" namespace"+m((t.cluster.stats.namespaces?.length||0)===1?"":"s"),1)):D("",!0),u("span",Uo,m(t.cluster.id),1)]),u("h2",Wo,m(t.cluster.title),1),u("p",Ho,m(t.cluster.plain_summary),1),u("div",{class:"rounded-lg p-3 mb-4 flex items-center gap-3",style:G({background:f(st)[t.cluster.verdict].bg,border:"1px solid "+f(st)[t.cluster.verdict].border})},[S(f(I),{icon:f(st)[t.cluster.verdict].icon,class:"w-5 h-5",style:G({color:f(st)[t.cluster.verdict].color})},null,8,["icon","style"]),u("div",null,[u("div",{class:"text-[12px] font-semibold",style:G({color:f(st)[t.cluster.verdict].color})},m(f(st)[t.cluster.verdict].phrase),5),u("div",Fo,m(t.cluster.verdict_text),1)])],4),t.cluster.recommendations?(b(),v("div",Go,[u("h3",Ko,[S(f(I),{icon:"tabler:sparkles",class:"w-3 h-3"}),o[8]||(o[8]=T(" AI recommendations ",-1)),u("button",{onClick:o[0]||(o[0]=a=>n("update:expandedRecs",!t.expandedRecs)),class:"ml-auto text-[10px] opacity-60 hover:opacity-100"},m(t.expandedRecs?"Collapse":"Expand"),1)]),t.expandedRecs?(b(),v("ul",qo,[(b(!0),v(X,null,ot(t.cluster.recommendations,a=>(b(),v("li",{key:a.id,class:"rounded p-2.5 flex items-start gap-2",style:G({background:f(Nt)[a.severity].bg,border:"1px solid var(--p-content-border-color)"})},[S(f(I),{icon:f(Nt)[a.severity].icon,class:"w-3.5 h-3.5 shrink-0 mt-0.5",style:G({color:f(Nt)[a.severity].color})},null,8,["icon","style"]),u("div",Yo,[u("div",Xo,m(a.text),1),a.fix_hint?(b(),v("div",Qo,"↳ "+m(a.fix_hint),1)):D("",!0),a.state==="open"?(b(),v("div",Zo,[S(f(lt),{onClick:l=>n("explain-rec",a.id),disabled:t.explaining===a.id,class:"k-btn-tinted k-btn-tinted-accent"},{default:Z(()=>[S(f(I),{icon:t.explaining===a.id?"tabler:loader-2":"tabler:sparkles",class:J(t.explaining===a.id?"w-3 h-3 animate-spin":"w-3 h-3")},null,8,["icon","class"]),T(" "+m(t.explaining===a.id?"Asking AI…":"Explain"),1)]),_:2},1032,["onClick","disabled"]),S(f(lt),{onClick:l=>n("ack-rec",a.id,"acknowledged"),class:"k-btn-tinted k-btn-tinted-info"},{default:Z(()=>[S(f(I),{icon:"tabler:eye-check",class:"w-3 h-3"}),o[9]||(o[9]=T(" Acknowledge ",-1))]),_:1},8,["onClick"]),S(f(lt),{onClick:l=>n("ack-rec",a.id,"fixed"),class:"k-btn-tinted k-btn-tinted-success"},{default:Z(()=>[S(f(I),{icon:"tabler:check",class:"w-3 h-3"}),o[10]||(o[10]=T(" Mark fixed ",-1))]),_:1},8,["onClick"])])):D("",!0),a.detail||t.explanations[a.id]?(b(),v("div",Jo,[u("div",tr,[S(f(I),{icon:"tabler:sparkles",class:"w-3 h-3"}),o[11]||(o[11]=T(" AI explanation ",-1))]),T(m(a.detail||t.explanations[a.id]),1)])):D("",!0)]),u("span",{class:"text-[9px] font-semibold uppercase px-1 py-0.5 rounded shrink-0",style:G({background:f(zt)[a.state].bg,color:f(zt)[a.state].color})},m(f(zt)[a.state].label),5)],4))),128))])):D("",!0)])):D("",!0),t.changes.length>0?(b(),v("div",er,[u("h3",nr,[S(f(I),{icon:"tabler:list",class:"w-3 h-3"}),T(" Changes ("+m(t.changes.length)+") ",1),o[12]||(o[12]=u("span",{class:"opacity-50 ml-auto text-[9px]"},"click a row for diff",-1))]),u("div",or,[(b(!0),v(X,null,ot(t.changes.slice(0,100),a=>(b(),v("div",{key:a.change_id,onClick:l=>n("open-diff",a.path),class:"px-3 py-1.5 border-b last:border-0 flex items-center gap-2 cursor-pointer hover:bg-[var(--p-content-hover-background)]",style:{"border-color":"var(--p-content-border-color)"}},[S(f(qt),{severity:a.op==="create"?"success":a.op==="delete"?"danger":"info",class:"!text-[9px] !px-1 !py-px !font-semibold !uppercase shrink-0"},{default:Z(()=>[T(m(a.op[0].toUpperCase()),1)]),_:2},1032,["severity"]),S(f(I),{icon:a.category==="registry"?"tabler:database":"tabler:file",class:"w-3 h-3 opacity-50 shrink-0"},null,8,["icon"]),u("span",ar,m(a.path),1),a.added?(b(),v("span",ir,"+"+m(a.added),1)):D("",!0),a.removed?(b(),v("span",sr,"−"+m(a.removed),1)):D("",!0)],8,rr))),128)),t.changes.length>100?(b(),v("div",lr," + "+m(t.changes.length-100)+" more ",1)):D("",!0)])])):D("",!0),u("div",dr,[t.cluster.decision==="pending"?(b(),v(X,{key:0},[S(f(lt),{onClick:o[1]||(o[1]=a=>n("decide",t.cluster.id,"approved")),disabled:t.blocking,severity:"success",class:"!px-4 !py-2 !rounded-lg !text-[12px] !font-medium !gap-1.5"},{default:Z(()=>[S(f(I),{icon:"tabler:check",class:"w-3.5 h-3.5"}),o[13]||(o[13]=T(" Mark ready ",-1))]),_:1},8,["disabled"]),u("button",{onClick:o[2]||(o[2]=a=>n("open-split")),class:"px-4 py-2 rounded-lg text-[12px] font-medium flex items-center gap-1.5",style:{background:"var(--kp-btn-secondary-bg)"}},[S(f(I),{icon:"tabler:arrow-split",class:"w-3.5 h-3.5"}),o[14]||(o[14]=T(" Split… ",-1))]),u("button",{onClick:o[3]||(o[3]=a=>n("decide",t.cluster.id,"skipped")),class:"px-4 py-2 rounded-lg text-[12px] flex items-center gap-1.5",style:{background:"var(--kp-btn-secondary-bg)"}},[S(f(I),{icon:"tabler:archive",class:"w-3.5 h-3.5"}),o[15]||(o[15]=T(" Hide ",-1))]),t.blocking?(b(),v("span",ur," Resolve blocking issue first ")):D("",!0)],64)):t.cluster.decision==="approved"?(b(),v(X,{key:1},[u("span",cr,[S(f(I),{icon:"tabler:circle-check",class:"w-3.5 h-3.5"}),o[16]||(o[16]=T(" Marked ready — push from header when ready to ship ",-1))]),t.cluster.pushable?(b(),tt(f(lt),{key:0,onClick:o[4]||(o[4]=a=>n("push-confirm")),severity:"success",class:"ml-auto !px-4 !py-2 !rounded-lg !text-[12px] !font-medium !gap-1.5"},{default:Z(()=>[S(f(I),{icon:"tabler:upload",class:"w-3.5 h-3.5"}),T(" Push all "+m(t.pushableReady),1)]),_:1})):(b(),v("span",pr,m(t.cluster.push_blockers?.[0]||"Review-only cluster"),1)),u("button",{onClick:o[5]||(o[5]=a=>n("decide",t.cluster.id,"pending")),class:"px-4 py-2 rounded-lg text-[12px]",style:{background:"var(--kp-btn-secondary-bg)"}}," Unmark ")],64)):(b(),v("button",{key:2,onClick:o[6]||(o[6]=a=>n("decide",t.cluster.id,"pending")),class:"px-4 py-2 rounded-lg text-[12px]",style:{background:"var(--kp-btn-secondary-bg)"}}," Move back to pending "))])])]))}}),gr={class:"rounded-lg w-full max-w-md mx-4 overflow-hidden",style:{background:"var(--p-content-background)",border:"1px solid var(--p-content-border-color)"}},fr={class:"px-5 py-3 border-b flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},vr={class:"text-[13px] font-semibold flex-1"},hr={class:"px-5 py-4"},yr={class:"rounded border mt-3",style:{"border-color":"var(--p-content-border-color)","max-height":"240px","overflow-y":"auto"}},mr={class:"text-[11px] flex-1 truncate"},kr={class:"text-[10px] opacity-60 shrink-0"},xr={class:"px-5 py-3 border-t flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},$r=["disabled"],wr=bt({__name:"GitPushConfirmModal",props:{open:{type:Boolean},count:{},pushing:{type:Boolean},clusters:{}},emits:["push","close"],setup(t,{emit:e}){const n=e;return(r,o)=>t.open?(b(),v("div",{key:0,class:"fixed inset-0 z-50 flex items-center justify-center",style:{background:"var(--p-mask-background)"},onClick:o[3]||(o[3]=Gt(a=>n("close"),["self"]))},[u("div",gr,[u("div",fr,[S(f(I),{icon:"tabler:upload",class:"w-4 h-4"}),u("h3",vr,"Push "+m(t.count)+" clusters to main",1),u("button",{onClick:o[0]||(o[0]=a=>n("close")),class:"opacity-60 hover:opacity-100"},[S(f(I),{icon:"tabler:x",class:"w-4 h-4"})])]),u("div",hr,[o[4]||(o[4]=u("p",{class:"text-[11px] opacity-80 leading-relaxed"},[T(" Each cluster runs through governance (lint → version → migrations → tests → registry → fs) and merges to main on success. Failed clusters stay in "),u("b",null,"Pending"),T(" with the failure attached. ")],-1)),u("div",yr,[(b(!0),v(X,null,ot(t.clusters,a=>(b(),v("div",{key:a.id,class:"px-3 py-2 border-b last:border-0 flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},[u("span",{class:"w-1.5 h-1.5 rounded-full shrink-0",style:G({background:f(At)[a.importance].dot})},null,4),u("span",mr,m(a.title),1),u("span",kr,m(f(Kt)(a.change_count)),1)]))),128))])]),u("div",xr,[S(f(lt),{onClick:o[1]||(o[1]=a=>n("push")),disabled:t.pushing,severity:"success",class:"!px-4 !py-1.5 !text-[12px] !font-semibold !gap-1.5"},{default:Z(()=>[S(f(I),{icon:t.pushing?"tabler:loader-2":"tabler:upload",class:J(t.pushing?"w-3.5 h-3.5 animate-spin":"w-3.5 h-3.5")},null,8,["icon","class"]),T(" "+m(t.pushing?"Pushing…":"Push all"),1)]),_:1},8,["disabled"]),u("button",{onClick:o[2]||(o[2]=a=>n("close")),disabled:t.pushing,class:"px-4 py-1.5 rounded text-[12px]",style:{background:"var(--kp-btn-secondary-bg)"}}," Cancel ",8,$r)])])])):D("",!0)}}),Sr={class:"rounded-lg w-full max-w-2xl mx-4 overflow-hidden flex flex-col",style:{background:"var(--p-content-background)",border:"1px solid var(--p-content-border-color)","max-height":"80vh"}},_r={class:"px-5 py-3 border-b flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},Pr={class:"text-[13px] font-semibold flex-1"},Cr={class:"opacity-70"},Tr={class:"px-5 py-2.5 border-b flex items-center gap-1 text-[11px]",style:{"border-color":"var(--p-content-border-color)"}},Or=["onClick","disabled"],Ar={class:"ml-auto opacity-60"},jr={class:"flex-1 overflow-y-auto p-4"},Ir={key:0,class:"p-12 text-center text-[12px] opacity-60"},Er={key:0},Lr={key:1},Br={key:1,class:"p-12 text-center text-[12px] opacity-60"},Nr={key:2},zr={class:"text-[11px] opacity-70 mb-3"},Dr={class:"space-y-2"},Vr={class:"flex items-baseline gap-2 mb-1"},Mr={class:"text-[12px] font-semibold flex-1 truncate"},Rr={class:"text-[10px] opacity-70"},Ur={key:0,class:"text-[11px] opacity-80 mb-1.5"},Wr={class:"font-mono text-[10px] opacity-60 space-y-0.5"},Hr={key:0},Fr={class:"px-5 py-3 border-t flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},Gr=bt({__name:"GitSplitModal",props:{open:{type:Boolean},title:{},changeCount:{},changes:{},mode:{},groups:{},loading:{type:Boolean},applying:{type:Boolean}},emits:["update:mode","apply","close"],setup(t,{emit:e}){const n=t,r=e;function o(l){const s=n.changes;if(!s)return[];const i={};for(const d of s)i[d.change_id]=d.path;return l.change_ids.slice(0,3).map(d=>i[d]||d)}const a=[{key:"by_prefix",icon:"tabler:folders",label:"By directory"},{key:"by_kind",icon:"tabler:category",label:"By file kind"},{key:"ai",icon:"tabler:sparkles",label:"AI suggest"}];return(l,s)=>t.open?(b(),v("div",{key:0,class:"fixed inset-0 z-50 flex items-center justify-center",style:{background:"var(--p-mask-background)"},onClick:s[3]||(s[3]=Gt(i=>r("close"),["self"]))},[u("div",Sr,[u("header",_r,[S(f(I),{icon:"tabler:arrow-split",class:"w-4 h-4"}),u("h3",Pr,[s[4]||(s[4]=T(" Split ",-1)),u("span",Cr,m(t.title),1)]),u("button",{onClick:s[0]||(s[0]=i=>r("close")),class:"opacity-60 hover:opacity-100"},[S(f(I),{icon:"tabler:x",class:"w-4 h-4"})])]),u("div",Tr,[s[5]||(s[5]=u("span",{class:"opacity-70 mr-1"},"Strategy:",-1)),(b(),v(X,null,ot(a,i=>u("button",{key:i.key,onClick:d=>r("update:mode",i.key),disabled:t.loading,class:"px-2 py-1 rounded font-medium flex items-center gap-1",style:G({background:t.mode===i.key?"var(--p-primary-color)":"var(--p-content-hover-background)",color:t.mode===i.key?"var(--p-primary-contrast-color)":"inherit"})},[S(f(I),{icon:i.icon,class:"w-3 h-3"},null,8,["icon"]),T(" "+m(i.label),1)],12,Or)),64)),u("span",Ar,m(t.changeCount)+" files in source cluster ",1)]),u("div",jr,[t.loading?(b(),v("div",Ir,[S(f(I),{icon:"tabler:loader-2",class:"w-5 h-5 animate-spin mx-auto mb-2"}),t.mode==="ai"?(b(),v("span",Er,"Asking Sonnet to propose sub-clusters…")):(b(),v("span",Lr,"Computing groups…"))])):t.groups.length===0?(b(),v("div",Br," No groups proposed. ")):(b(),v("div",Nr,[u("p",zr,[s[6]||(s[6]=T(" Will create ",-1)),u("b",null,m(t.groups.length),1),T(" new clusters. Source cluster will be "+m(t.groups.reduce((i,d)=>i+d.change_ids.length,0)>=t.changeCount?"removed":"reduced")+". ",1)]),u("ul",Dr,[(b(!0),v(X,null,ot(t.groups,(i,d)=>(b(),v("li",{key:d,class:"rounded p-3",style:{background:"var(--p-content-hover-background)",border:"1px solid var(--p-content-border-color)"}},[u("div",Vr,[u("span",Mr,m(i.title),1),u("span",Rr,m(i.change_ids.length)+" files",1)]),i.plain_summary?(b(),v("p",Ur,m(i.plain_summary),1)):D("",!0),u("div",Wr,[(b(!0),v(X,null,ot(o(i),c=>(b(),v("div",{key:c,class:"truncate"},m(c),1))),128)),i.change_ids.length>3?(b(),v("div",Hr,"+ "+m(i.change_ids.length-3)+" more",1)):D("",!0)])]))),128))])]))]),u("div",Fr,[S(f(lt),{onClick:s[1]||(s[1]=i=>r("apply")),disabled:t.loading||t.applying||t.groups.length<2,severity:"success",class:"!px-4 !py-1.5 !text-[12px] !font-semibold !gap-1.5"},{default:Z(()=>[S(f(I),{icon:t.applying?"tabler:loader-2":"tabler:arrow-split",class:J(t.applying?"w-3.5 h-3.5 animate-spin":"w-3.5 h-3.5")},null,8,["icon","class"]),T(" "+m(t.applying?"Splitting…":`Apply (creates ${t.groups.length} clusters)`),1)]),_:1},8,["disabled"]),u("button",{onClick:s[2]||(s[2]=i=>r("close")),class:"px-4 py-1.5 rounded text-[12px] ml-auto",style:{background:"var(--kp-btn-secondary-bg)"}},"Cancel")])])])):D("",!0)}}),Kr={class:"ml-auto w-[820px] h-full overflow-hidden flex flex-col",style:{background:"var(--p-content-background)","border-left":"1px solid var(--p-content-border-color)"}},qr={class:"px-4 py-2.5 border-b flex items-center gap-2",style:{"border-color":"var(--p-content-border-color)"}},Yr={class:"text-[11px] font-mono flex-1 truncate"},Xr={key:0,class:"p-12 text-center text-[12px] opacity-60"},Qr={key:1,class:"p-12 text-center text-[12px] opacity-60"},Zr={key:2,class:"flex-1 overflow-y-auto font-mono text-[11px] leading-snug"},Jr={class:"px-3 py-1 sticky top-0 z-10 text-[10px] opacity-60",style:{background:"var(--p-content-hover-background)","border-bottom":"1px solid var(--p-content-border-color)"}},ta={class:"w-10 text-right pr-2 opacity-40 select-none shrink-0"},ea={class:"w-10 text-right pr-2 opacity-40 select-none shrink-0"},na={class:"w-4 text-center opacity-60 select-none shrink-0"},oa=bt({__name:"GitDiffModal",props:{path:{},data:{},loading:{type:Boolean}},emits:["close"],setup(t,{emit:e}){const n=e;return(r,o)=>t.path?(b(),v("div",{key:0,class:"fixed inset-0 z-50 flex",style:{background:"var(--p-mask-background)"},onClick:o[1]||(o[1]=Gt(a=>n("close"),["self"]))},[u("aside",Kr,[u("header",qr,[S(f(I),{icon:"tabler:diff",class:"w-4 h-4"}),u("span",Yr,m(t.path),1),u("button",{onClick:o[0]||(o[0]=a=>n("close")),class:"opacity-60 hover:opacity-100"},[S(f(I),{icon:"tabler:x",class:"w-4 h-4"})])]),t.loading?(b(),v("div",Xr,[S(f(I),{icon:"tabler:loader-2",class:"w-5 h-5 animate-spin mx-auto mb-2"}),o[2]||(o[2]=T(" Loading diff… ",-1))])):!t.data||t.data.hunks.length===0&&!t.data.diff_text?(b(),v("div",Qr," No diff (file may be untracked or identical to base). ")):(b(),v("div",Zr,[(b(!0),v(X,null,ot(t.data.hunks,(a,l)=>(b(),v("div",{key:l},[u("div",Jr,m(a.header),1),(b(!0),v(X,null,ot(a.lines,(s,i)=>(b(),v("pre",{key:i,class:J(["px-0 py-0.5 flex whitespace-pre",{"bg-success-500/5 text-success-500":s.kind==="+","bg-danger-500/5 text-danger-500":s.kind==="-"}])},[o[3]||(o[3]=T("            ",-1)),u("span",ta,m(s.old_no||""),1),o[4]||(o[4]=T(`
            `,-1)),u("span",ea,m(s.new_no||""),1),o[5]||(o[5]=T(`
            `,-1)),u("span",na,m(s.kind===" "?"":s.kind),1),o[6]||(o[6]=T(`
            `,-1)),u("span",null,m(s.text),1),o[7]||(o[7]=T(`
          `,-1))],2))),128))]))),128))]))])])):D("",!0)}}),ra={class:"flex flex-col h-full"},aa={class:"flex-1 grid grid-cols-[400px_1fr] overflow-hidden"},ia={key:0,class:"overflow-y-auto",style:{background:"var(--p-content-background)"}},pa=bt({__name:"git",setup(t){const e=Ke(),n=Ge(),r=qe(),o=Qe(e,r),a=M("all"),l=M(null),s=M(!0),i=M(!1),d=M(!1);function c($,h="info"){n.toast({severity:h,summary:$,life:4e3})}Ie(async()=>{await o.refresh(),(!o.snapshot.value||(o.snapshot.value.clusters||[]).length===0)&&c("No cluster index yet — click Rebuild to build one.")}),Jt(()=>o.snapshot.value?.clusters?.length,()=>{l.value&&!o.snapshot.value?.clusters.find($=>$.id===l.value)&&(l.value=null),!l.value&&p.value.length>0&&(l.value=p.value[0].id)}),Jt(l,async $=>{if(!$){o.detail.value=null;return}try{await o.loadCluster($)}catch(h){c(it(h)||"failed to load cluster","error")}});const p=nt(()=>{let h=(o.snapshot.value?.clusters||[]).slice();a.value==="suspect"?h=h.filter(F=>F.decision==="orphan"||F.importance==="suspect"):a.value==="pending"?h=h.filter(F=>F.decision==="pending"):a.value==="ready"?h=h.filter(F=>F.decision==="approved"):a.value==="hidden"&&(h=h.filter(F=>F.decision==="skipped"||F.decision==="split"));const U=F=>F==="pending"?0:F==="approved"?1:2;return h.sort((F,Te)=>U(F.decision)-U(Te.decision))}),g=nt(()=>o.detail.value||p.value[0]||null),k=nt(()=>g.value?.changes||[]),_=nt(()=>o.snapshot.value?.counts||{all:0,pending:0,ready:0,hidden:0,suspect:0,pushable_ready:0,blocked_ready:0}),B=nt(()=>(o.snapshot.value?.clusters||[]).length>0),L=nt(()=>(o.snapshot.value?.clusters||[]).filter($=>$.decision==="approved"&&$.pushable)),N=nt(()=>{const $=o.snapshot.value?.built_at;if(!$)return"never";const h=Math.max(0,Math.floor((Date.now()-new Date($).getTime())/6e4));return h<1?"just now":h===1?"1 min ago":h<60?h+" min ago":Math.floor(h/60)+" h ago"}),R=nt(()=>{const $=g.value?.recommendations;return $?$.some(h=>h.severity==="block"&&h.state==="open"):!1});async function V($,h){try{await o.setDecision($,h)}catch(U){c(it(U)||"failed","error")}}async function y($,h){if(g.value)try{await o.updateRecommendation(g.value.id,$,h)}catch(U){c(it(U)||"failed","error")}}async function j($){try{await o.rebuild({mode:$,sync_first:d.value})}catch(h){c(it(h)||"rebuild failed","error")}}async function q(){const $=L.value.map(h=>h.id);if($.length===0){i.value=!1;return}try{const h=await o.pushApproved($);i.value=!1;const U=h.pushed+h.failed,F=h.failed>0?"error":"success";c(`Pushed ${h.pushed} of ${U} clusters`,F)}catch(h){c(it(h)||"push failed","error")}}const rt=M(null),gt=M(null),w=M(!1);async function x($){rt.value=$,gt.value=null,w.value=!0;try{gt.value=await o.fetchDiff($)}catch(h){c(it(h)||"diff failed","error")}finally{w.value=!1}}function C(){rt.value=null,gt.value=null}const A=M(!1),z=M("by_prefix"),Y=M([]),at=M(!1),pt=M(!1);async function we(){g.value&&(A.value=!0,z.value="by_prefix",await Yt())}async function Yt(){if(g.value){at.value=!0,Y.value=[];try{const $=await o.suggestSplit(g.value.id,{mode:z.value});Y.value=$.groups||[]}catch($){c(it($)||"split suggestion failed","error")}finally{at.value=!1}}}function Se($){z.value=$,Yt()}async function _e(){if(!(!g.value||Y.value.length===0)){pt.value=!0;try{const $=Y.value.filter(h=>h.change_ids.length>0);if($.length<2)throw new Error("need at least 2 non-empty groups to split");await o.splitCluster(g.value.id,$),A.value=!1,c(`Split into ${$.length} clusters`,"success")}catch($){c(it($)||"split apply failed","error")}finally{pt.value=!1}}}function Pe(){A.value=!1,Y.value=[]}const Et=M(null),Xt=M({});async function Ce($){if(g.value){Et.value=$;try{const h=await o.explainRecommendation(g.value.id,$);h.text&&(Xt.value[$]=h.text)}catch(h){c(it(h)||"explain failed","error")}finally{Et.value=null}}}return($,h)=>(b(),v("div",ra,[S(lo,{stale:f(o).stale.value,rebuilding:f(o).rebuilding.value,"index-age-text":N.value,"journal-size":f(o).snapshot.value?.journal_size_at_build??null,counts:_.value,"sync-first":d.value,onRebuild:j,onPushConfirm:h[0]||(h[0]=U=>i.value=!0),"onUpdate:syncFirst":h[1]||(h[1]=U=>d.value=U)},null,8,["stale","rebuilding","index-age-text","journal-size","counts","sync-first"]),u("main",aa,[S(Lo,{clusters:p.value,counts:_.value,filter:a.value,"selected-id":g.value?.id??null,loading:f(o).loading.value,error:f(o).error.value,"has-any-clusters":B.value,"onUpdate:filter":h[2]||(h[2]=U=>{a.value=U,l.value=null}),onSelect:h[3]||(h[3]=U=>l.value=U)},null,8,["clusters","counts","filter","selected-id","loading","error","has-any-clusters"]),g.value?(b(),tt(br,{key:1,cluster:g.value,changes:k.value,blocking:R.value,"pushable-ready":_.value.pushable_ready||0,"expanded-recs":s.value,explaining:Et.value,explanations:Xt.value,onDecide:V,onAckRec:y,onExplainRec:Ce,onOpenSplit:we,onOpenDiff:x,onPushConfirm:h[4]||(h[4]=U=>i.value=!0),"onUpdate:expandedRecs":h[5]||(h[5]=U=>s.value=U)},null,8,["cluster","changes","blocking","pushable-ready","expanded-recs","explaining","explanations"])):(b(),v("div",ia,[...h[7]||(h[7]=[u("div",{class:"p-12 text-center text-[12px] opacity-60"}," Pick a cluster on the left. ",-1)])]))]),S(wr,{open:i.value,count:_.value.pushable_ready||0,pushing:f(o).pushing.value,clusters:L.value,onPush:q,onClose:h[6]||(h[6]=U=>i.value=!1)},null,8,["open","count","pushing","clusters"]),S(Gr,{open:A.value&&g.value!==null,title:g.value?.title??"","change-count":g.value?.change_count??0,changes:g.value?.changes??null,mode:z.value,groups:Y.value,loading:at.value,applying:pt.value,"onUpdate:mode":Se,onApply:_e,onClose:Pe},null,8,["open","title","change-count","changes","mode","groups","loading","applying"]),S(oa,{path:rt.value,data:gt.value,loading:w.value,onClose:C},null,8,["path","data","loading"])]))}});export{pa as default};
//# sourceMappingURL=git-Yf00r_05.js.map
