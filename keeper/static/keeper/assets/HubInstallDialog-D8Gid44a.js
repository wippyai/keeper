import{openBlock as u,createElementBlock as d,mergeProps as w,createElementVNode as f,renderSlot as P,createBlock as G,Teleport as nn,createCommentVNode as b,computed as Y,resolveComponent as ae,resolveDirective as ht,withCtx as ne,createVNode as H,Transition as gt,withDirectives as Se,Fragment as q,normalizeClass as ee,toDisplayString as y,resolveDynamicComponent as Ie,createTextVNode as F,renderList as re,normalizeStyle as Mn,createSlots as An,defineComponent as qe,ref as U,watch as on,onBeforeUnmount as Dn,unref as W,withKeys as rt,withModifiers as Vn,useId as Vt,shallowRef as we,vModelText as Tt,vModelCheckbox as Tn}from"vue";import{D as Ke,F as he,L as Bn,G as ie,H as ze,I as Fn,U as Rn,J as Bt,K as fe,M as jn,N as Kn,O as sn,P as Hn,s as Nn,R as vt,Q as He,S as me,T as an,V as Un,W as Gn,X as rn,Y as Wn,Z as Zn,$ as Yn,a0 as Xn,a1 as ln,a2 as un,a3 as Ft,a4 as Le,a5 as Pe,a6 as lt,a7 as Jn,a8 as Qn,a9 as qn,aa as ei,ab as ti,ac as _e,u as dn,l as ni,_ as cn}from"../app.js";import{Icon as le}from"@iconify/vue";function ii(){let t=[],e=(c,p,m=999)=>{let g=s(c,p,m),h=g.value+(g.key===c?0:m)+1;return t.push({key:c,value:h}),h},n=c=>{t=t.filter(p=>p.value!==c)},i=(c,p)=>s(c).value,s=(c,p,m=0)=>[...t].reverse().find(g=>!0)||{key:c,value:m},o=c=>c&&parseInt(c.style.zIndex,10)||0;return{get:o,set:(c,p,m)=>{p&&(p.style.zIndex=String(e(c,!0,m)))},clear:c=>{c&&(n(o(c)),c.style.zIndex="")},getCurrent:c=>i(c)}}var Oe=ii();function Ee(t){const e=t.response?.data;return{code:e?.code,message:e?.error||e?.message||t.message||"Request failed",details:e?.details}}function oi(){return{removed:[],kept:[],kept_under_uncertainty:[],warnings:[]}}async function si(t,e={}){const n={};e.component&&(n.component=e.component),e.entries===!1&&(n.entries=!1),e.migrations===!1&&(n.migrations=!1),e.modules===!1&&(n.modules=!1);const{data:i}=await t.get("/api/v1/keeper/hub/dependencies",{params:n});return i}async function ai(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/install",e);return n}async function ri(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/plan",e);return n}async function li(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/fill-gaps",e);return n}async function mr(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/uninstall",e);return n}async function hr(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/uninstall",{...e,dry_run:!0}),i=n?.preview;return i?{removed:i.removed||[],kept:i.kept||[],kept_under_uncertainty:i.kept_under_uncertainty||[],warnings:i.warnings||[]}:oi()}async function ui(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/scan",e);return n}async function gr(t,e={}){const n={};e.component&&(n.component=e.component),e.entry_ids&&e.entry_ids.length&&(n.entry_ids=e.entry_ids.join(","));const{data:i}=await t.get("/api/v1/keeper/hub/migrations",{params:n});return i}async function vr(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/migrations/run",e);return n}async function yr(t,e={}){const n={};e.query&&(n.q=e.query),e.page&&(n.page=e.page),e.page_size&&(n.page_size=e.page_size),e.visibility&&(n.visibility=e.visibility),e.type&&(n.type=e.type),e.sort&&(n.sort=e.sort);const{data:i}=await t.get("/api/v1/keeper/hub/browse",{params:n});return i}async function br(t,e,n={}){const i={module:e};n.page&&(i.page=n.page),n.page_size&&(i.page_size=n.page_size);const{data:s}=await t.get("/api/v1/keeper/hub/versions",{params:i});return s}async function wr(t,e,n){const i={module:e},{data:s}=await t.get("/api/v1/keeper/hub/readme",{params:i});return s}var et={name:"TimesIcon",extends:Ke};function di(t){return mi(t)||fi(t)||pi(t)||ci()}function ci(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function pi(t,e){if(t){if(typeof t=="string")return ut(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ut(t,e):void 0}}function fi(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function mi(t){if(Array.isArray(t))return ut(t)}function ut(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function hi(t,e,n,i,s,o){return u(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),di(e[0]||(e[0]=[f("path",{d:"M8.01186 7.00933L12.27 2.75116C12.341 2.68501 12.398 2.60524 12.4375 2.51661C12.4769 2.42798 12.4982 2.3323 12.4999 2.23529C12.5016 2.13827 12.4838 2.0419 12.4474 1.95194C12.4111 1.86197 12.357 1.78024 12.2884 1.71163C12.2198 1.64302 12.138 1.58893 12.0481 1.55259C11.9581 1.51625 11.8617 1.4984 11.7647 1.50011C11.6677 1.50182 11.572 1.52306 11.4834 1.56255C11.3948 1.60204 11.315 1.65898 11.2488 1.72997L6.99067 5.98814L2.7325 1.72997C2.59553 1.60234 2.41437 1.53286 2.22718 1.53616C2.03999 1.53946 1.8614 1.61529 1.72901 1.74767C1.59663 1.88006 1.5208 2.05865 1.5175 2.24584C1.5142 2.43303 1.58368 2.61419 1.71131 2.75116L5.96948 7.00933L1.71131 11.2675C1.576 11.403 1.5 11.5866 1.5 11.7781C1.5 11.9696 1.576 12.1532 1.71131 12.2887C1.84679 12.424 2.03043 12.5 2.2219 12.5C2.41338 12.5 2.59702 12.424 2.7325 12.2887L6.99067 8.03052L11.2488 12.2887C11.3843 12.424 11.568 12.5 11.7594 12.5C11.9509 12.5 12.1346 12.424 12.27 12.2887C12.4053 12.1532 12.4813 11.9696 12.4813 11.7781C12.4813 11.5866 12.4053 11.403 12.27 11.2675L8.01186 7.00933Z",fill:"currentColor"},null,-1)])),16)}et.render=hi;var pn={name:"WindowMaximizeIcon",extends:Ke};function gi(t){return wi(t)||bi(t)||yi(t)||vi()}function vi(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function yi(t,e){if(t){if(typeof t=="string")return dt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?dt(t,e):void 0}}function bi(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function wi(t){if(Array.isArray(t))return dt(t)}function dt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function Ci(t,e,n,i,s,o){return u(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),gi(e[0]||(e[0]=[f("path",{"fill-rule":"evenodd","clip-rule":"evenodd",d:"M7 14H11.8C12.3835 14 12.9431 13.7682 13.3556 13.3556C13.7682 12.9431 14 12.3835 14 11.8V2.2C14 1.61652 13.7682 1.05694 13.3556 0.644365C12.9431 0.231785 12.3835 0 11.8 0H2.2C1.61652 0 1.05694 0.231785 0.644365 0.644365C0.231785 1.05694 0 1.61652 0 2.2V7C0 7.15913 0.063214 7.31174 0.175736 7.42426C0.288258 7.53679 0.44087 7.6 0.6 7.6C0.75913 7.6 0.911742 7.53679 1.02426 7.42426C1.13679 7.31174 1.2 7.15913 1.2 7V2.2C1.2 1.93478 1.30536 1.68043 1.49289 1.49289C1.68043 1.30536 1.93478 1.2 2.2 1.2H11.8C12.0652 1.2 12.3196 1.30536 12.5071 1.49289C12.6946 1.68043 12.8 1.93478 12.8 2.2V11.8C12.8 12.0652 12.6946 12.3196 12.5071 12.5071C12.3196 12.6946 12.0652 12.8 11.8 12.8H7C6.84087 12.8 6.68826 12.8632 6.57574 12.9757C6.46321 13.0883 6.4 13.2409 6.4 13.4C6.4 13.5591 6.46321 13.7117 6.57574 13.8243C6.68826 13.9368 6.84087 14 7 14ZM9.77805 7.42192C9.89013 7.534 10.0415 7.59788 10.2 7.59995C10.3585 7.59788 10.5099 7.534 10.622 7.42192C10.7341 7.30985 10.798 7.15844 10.8 6.99995V3.94242C10.8066 3.90505 10.8096 3.86689 10.8089 3.82843C10.8079 3.77159 10.7988 3.7157 10.7824 3.6623C10.756 3.55552 10.701 3.45698 10.622 3.37798C10.5099 3.2659 10.3585 3.20202 10.2 3.19995H7.00002C6.84089 3.19995 6.68828 3.26317 6.57576 3.37569C6.46324 3.48821 6.40002 3.64082 6.40002 3.79995C6.40002 3.95908 6.46324 4.11169 6.57576 4.22422C6.68828 4.33674 6.84089 4.39995 7.00002 4.39995H8.80006L6.19997 7.00005C6.10158 7.11005 6.04718 7.25246 6.04718 7.40005C6.04718 7.54763 6.10158 7.69004 6.19997 7.80005C6.30202 7.91645 6.44561 7.98824 6.59997 8.00005C6.75432 7.98824 6.89791 7.91645 6.99997 7.80005L9.60002 5.26841V6.99995C9.6021 7.15844 9.66598 7.30985 9.77805 7.42192ZM1.4 14H3.8C4.17066 13.9979 4.52553 13.8498 4.78763 13.5877C5.04973 13.3256 5.1979 12.9707 5.2 12.6V10.2C5.1979 9.82939 5.04973 9.47452 4.78763 9.21242C4.52553 8.95032 4.17066 8.80215 3.8 8.80005H1.4C1.02934 8.80215 0.674468 8.95032 0.412371 9.21242C0.150274 9.47452 0.00210008 9.82939 0 10.2V12.6C0.00210008 12.9707 0.150274 13.3256 0.412371 13.5877C0.674468 13.8498 1.02934 13.9979 1.4 14ZM1.25858 10.0586C1.29609 10.0211 1.34696 10 1.4 10H3.8C3.85304 10 3.90391 10.0211 3.94142 10.0586C3.97893 10.0961 4 10.147 4 10.2V12.6C4 12.6531 3.97893 12.704 3.94142 12.7415C3.90391 12.779 3.85304 12.8 3.8 12.8H1.4C1.34696 12.8 1.29609 12.779 1.25858 12.7415C1.22107 12.704 1.2 12.6531 1.2 12.6V10.2C1.2 10.147 1.22107 10.0961 1.25858 10.0586Z",fill:"currentColor"},null,-1)])),16)}pn.render=Ci;var fn={name:"WindowMinimizeIcon",extends:Ke};function Si(t){return xi(t)||ki(t)||Ii(t)||Oi()}function Oi(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Ii(t,e){if(t){if(typeof t=="string")return ct(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ct(t,e):void 0}}function ki(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function xi(t){if(Array.isArray(t))return ct(t)}function ct(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function $i(t,e,n,i,s,o){return u(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),Si(e[0]||(e[0]=[f("path",{"fill-rule":"evenodd","clip-rule":"evenodd",d:"M11.8 0H2.2C1.61652 0 1.05694 0.231785 0.644365 0.644365C0.231785 1.05694 0 1.61652 0 2.2V7C0 7.15913 0.063214 7.31174 0.175736 7.42426C0.288258 7.53679 0.44087 7.6 0.6 7.6C0.75913 7.6 0.911742 7.53679 1.02426 7.42426C1.13679 7.31174 1.2 7.15913 1.2 7V2.2C1.2 1.93478 1.30536 1.68043 1.49289 1.49289C1.68043 1.30536 1.93478 1.2 2.2 1.2H11.8C12.0652 1.2 12.3196 1.30536 12.5071 1.49289C12.6946 1.68043 12.8 1.93478 12.8 2.2V11.8C12.8 12.0652 12.6946 12.3196 12.5071 12.5071C12.3196 12.6946 12.0652 12.8 11.8 12.8H7C6.84087 12.8 6.68826 12.8632 6.57574 12.9757C6.46321 13.0883 6.4 13.2409 6.4 13.4C6.4 13.5591 6.46321 13.7117 6.57574 13.8243C6.68826 13.9368 6.84087 14 7 14H11.8C12.3835 14 12.9431 13.7682 13.3556 13.3556C13.7682 12.9431 14 12.3835 14 11.8V2.2C14 1.61652 13.7682 1.05694 13.3556 0.644365C12.9431 0.231785 12.3835 0 11.8 0ZM6.368 7.952C6.44137 7.98326 6.52025 7.99958 6.6 8H9.8C9.95913 8 10.1117 7.93678 10.2243 7.82426C10.3368 7.71174 10.4 7.55913 10.4 7.4C10.4 7.24087 10.3368 7.08826 10.2243 6.97574C10.1117 6.86321 9.95913 6.8 9.8 6.8H8.048L10.624 4.224C10.73 4.11026 10.7877 3.95982 10.7849 3.80438C10.7822 3.64894 10.7192 3.50063 10.6093 3.3907C10.4994 3.28077 10.3511 3.2178 10.1956 3.21506C10.0402 3.21232 9.88974 3.27002 9.776 3.376L7.2 5.952V4.2C7.2 4.04087 7.13679 3.88826 7.02426 3.77574C6.91174 3.66321 6.75913 3.6 6.6 3.6C6.44087 3.6 6.28826 3.66321 6.17574 3.77574C6.06321 3.88826 6 4.04087 6 4.2V7.4C6.00042 7.47975 6.01674 7.55862 6.048 7.632C6.07656 7.70442 6.11971 7.7702 6.17475 7.82524C6.2298 7.88029 6.29558 7.92344 6.368 7.952ZM1.4 8.80005H3.8C4.17066 8.80215 4.52553 8.95032 4.78763 9.21242C5.04973 9.47452 5.1979 9.82939 5.2 10.2V12.6C5.1979 12.9707 5.04973 13.3256 4.78763 13.5877C4.52553 13.8498 4.17066 13.9979 3.8 14H1.4C1.02934 13.9979 0.674468 13.8498 0.412371 13.5877C0.150274 13.3256 0.00210008 12.9707 0 12.6V10.2C0.00210008 9.82939 0.150274 9.47452 0.412371 9.21242C0.674468 8.95032 1.02934 8.80215 1.4 8.80005ZM3.94142 12.7415C3.97893 12.704 4 12.6531 4 12.6V10.2C4 10.147 3.97893 10.0961 3.94142 10.0586C3.90391 10.0211 3.85304 10 3.8 10H1.4C1.34696 10 1.29609 10.0211 1.25858 10.0586C1.22107 10.0961 1.2 10.147 1.2 10.2V12.6C1.2 12.6531 1.22107 12.704 1.25858 12.7415C1.29609 12.779 1.34696 12.8 1.4 12.8H3.8C3.85304 12.8 3.90391 12.779 3.94142 12.7415Z",fill:"currentColor"},null,-1)])),16)}fn.render=$i;var zi=he.extend({name:"focustrap-directive"}),Li=Fn.extend({style:zi});function Ae(t){"@babel/helpers - typeof";return Ae=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Ae(t)}function Rt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function jt(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Rt(Object(n),!0).forEach(function(i){Pi(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Rt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function Pi(t,e,n){return(e=_i(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function _i(t){var e=Ei(t,"string");return Ae(e)=="symbol"?e:e+""}function Ei(t,e){if(Ae(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Ae(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Mi=Li.extend("focustrap",{mounted:function(e,n){var i=n.value||{},s=i.disabled;s||(this.createHiddenFocusableElements(e,n),this.bind(e,n),this.autoElementFocus(e,n)),e.setAttribute("data-pd-focustrap",!0),this.$el=e},updated:function(e,n){var i=n.value||{},s=i.disabled;s&&this.unbind(e)},unmounted:function(e){this.unbind(e)},methods:{getComputedSelector:function(e){return':not(.p-hidden-focusable):not([data-p-hidden-focusable="true"])'.concat(e??"")},bind:function(e,n){var i=this,s=n.value||{},o=s.onFocusIn,c=s.onFocusOut;e.$_pfocustrap_mutationobserver=new MutationObserver(function(p){p.forEach(function(m){if(m.type==="childList"&&!e.contains(document.activeElement)){var g=function(v){var S=Bt(v)?Bt(v,i.getComputedSelector(e.$_pfocustrap_focusableselector))?v:ze(e,i.getComputedSelector(e.$_pfocustrap_focusableselector)):ze(v);return fe(S)?S:v.nextSibling&&g(v.nextSibling)};ie(g(m.nextSibling))}})}),e.$_pfocustrap_mutationobserver.disconnect(),e.$_pfocustrap_mutationobserver.observe(e,{childList:!0}),e.$_pfocustrap_focusinlistener=function(p){return o&&o(p)},e.$_pfocustrap_focusoutlistener=function(p){return c&&c(p)},e.addEventListener("focusin",e.$_pfocustrap_focusinlistener),e.addEventListener("focusout",e.$_pfocustrap_focusoutlistener)},unbind:function(e){e.$_pfocustrap_mutationobserver&&e.$_pfocustrap_mutationobserver.disconnect(),e.$_pfocustrap_focusinlistener&&e.removeEventListener("focusin",e.$_pfocustrap_focusinlistener)&&(e.$_pfocustrap_focusinlistener=null),e.$_pfocustrap_focusoutlistener&&e.removeEventListener("focusout",e.$_pfocustrap_focusoutlistener)&&(e.$_pfocustrap_focusoutlistener=null)},autoFocus:function(e){this.autoElementFocus(this.$el,{value:jt(jt({},e),{},{autoFocus:!0})})},autoElementFocus:function(e,n){var i=n.value||{},s=i.autoFocusSelector,o=s===void 0?"":s,c=i.firstFocusableSelector,p=c===void 0?"":c,m=i.autoFocus,g=m===void 0?!1:m,h=ze(e,"[autofocus]".concat(this.getComputedSelector(o)));g&&!h&&(h=ze(e,this.getComputedSelector(p))),ie(h)},onFirstHiddenElementFocus:function(e){var n,i=e.currentTarget,s=e.relatedTarget,o=s===i.$_pfocustrap_lasthiddenfocusableelement||!((n=this.$el)!==null&&n!==void 0&&n.contains(s))?ze(i.parentElement,this.getComputedSelector(i.$_pfocustrap_focusableselector)):i.$_pfocustrap_lasthiddenfocusableelement;ie(o)},onLastHiddenElementFocus:function(e){var n,i=e.currentTarget,s=e.relatedTarget,o=s===i.$_pfocustrap_firsthiddenfocusableelement||!((n=this.$el)!==null&&n!==void 0&&n.contains(s))?Bn(i.parentElement,this.getComputedSelector(i.$_pfocustrap_focusableselector)):i.$_pfocustrap_firsthiddenfocusableelement;ie(o)},createHiddenFocusableElements:function(e,n){var i=this,s=n.value||{},o=s.tabIndex,c=o===void 0?0:o,p=s.firstFocusableSelector,m=p===void 0?"":p,g=s.lastFocusableSelector,h=g===void 0?"":g,v=function(L){return Rn("span",{class:"p-hidden-accessible p-hidden-focusable",tabIndex:c,role:"presentation","aria-hidden":!0,"data-p-hidden-accessible":!0,"data-p-hidden-focusable":!0,onFocus:L?.bind(i)})},S=v(this.onFirstHiddenElementFocus),C=v(this.onLastHiddenElementFocus);S.$_pfocustrap_lasthiddenfocusableelement=C,S.$_pfocustrap_focusableselector=m,S.setAttribute("data-pc-section","firstfocusableelement"),C.$_pfocustrap_firsthiddenfocusableelement=S,C.$_pfocustrap_focusableselector=h,C.setAttribute("data-pc-section","lastfocusableelement"),e.prepend(S),e.append(C)}}}),yt={name:"Portal",props:{appendTo:{type:[String,Object],default:"body"},disabled:{type:Boolean,default:!1}},data:function(){return{mounted:!1}},mounted:function(){this.mounted=jn()},computed:{inline:function(){return this.disabled||this.appendTo==="self"}}};function Ai(t,e,n,i,s,o){return o.inline?P(t.$slots,"default",{key:0}):s.mounted?(u(),G(nn,{key:1,to:n.appendTo},[P(t.$slots,"default")],8,["to"])):b("",!0)}yt.render=Ai;function Kt(){Hn({variableName:sn("scrollbar.width").name})}function Ht(){Kn({variableName:sn("scrollbar.width").name})}var Di=`
    .p-dialog {
        max-height: 90%;
        transform: scale(1);
        border-radius: dt('dialog.border.radius');
        box-shadow: dt('dialog.shadow');
        background: dt('dialog.background');
        border: 1px solid dt('dialog.border.color');
        color: dt('dialog.color');
        will-change: transform;
    }

    .p-dialog-content {
        overflow-y: auto;
        padding: dt('dialog.content.padding');
        flex-grow: 1;
    }

    .p-dialog-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-shrink: 0;
        padding: dt('dialog.header.padding');
    }

    .p-dialog-title {
        font-weight: dt('dialog.title.font.weight');
        font-size: dt('dialog.title.font.size');
    }

    .p-dialog-footer {
        flex-shrink: 0;
        padding: dt('dialog.footer.padding');
        display: flex;
        justify-content: flex-end;
        gap: dt('dialog.footer.gap');
    }

    .p-dialog-header-actions {
        display: flex;
        align-items: center;
        gap: dt('dialog.header.gap');
    }

    .p-dialog-top .p-dialog,
    .p-dialog-bottom .p-dialog,
    .p-dialog-left .p-dialog,
    .p-dialog-right .p-dialog,
    .p-dialog-topleft .p-dialog,
    .p-dialog-topright .p-dialog,
    .p-dialog-bottomleft .p-dialog,
    .p-dialog-bottomright .p-dialog {
        margin: 1rem;
    }

    .p-dialog-maximized {
        width: 100vw !important;
        height: 100vh !important;
        top: 0px !important;
        left: 0px !important;
        max-height: 100%;
        height: 100%;
        border-radius: 0;
    }

    .p-dialog .p-resizable-handle {
        position: absolute;
        font-size: 0.1px;
        display: block;
        cursor: se-resize;
        width: 12px;
        height: 12px;
        right: 1px;
        bottom: 1px;
    }

    .p-dialog-enter-active {
        animation: p-animate-dialog-enter 300ms cubic-bezier(.19,1,.22,1);
    }

    .p-dialog-leave-active {
        animation: p-animate-dialog-leave 300ms cubic-bezier(.19,1,.22,1);
    }

    @keyframes p-animate-dialog-enter {
        from {
            opacity: 0;
            transform: scale(0.93);
        }
    }

    @keyframes p-animate-dialog-leave {
        to {
            opacity: 0;
            transform: scale(0.93);
        }
    }
`,Vi={mask:function(e){var n=e.position,i=e.modal;return{position:"fixed",height:"100%",width:"100%",left:0,top:0,display:"flex",justifyContent:n==="left"||n==="topleft"||n==="bottomleft"?"flex-start":n==="right"||n==="topright"||n==="bottomright"?"flex-end":"center",alignItems:n==="top"||n==="topleft"||n==="topright"?"flex-start":n==="bottom"||n==="bottomleft"||n==="bottomright"?"flex-end":"center",pointerEvents:i?"auto":"none"}},root:{display:"flex",flexDirection:"column",pointerEvents:"auto"}},Ti={mask:function(e){var n=e.props,i=["left","right","top","topleft","topright","bottom","bottomleft","bottomright"],s=i.find(function(o){return o===n.position});return["p-dialog-mask",{"p-overlay-mask p-overlay-mask-enter-active":n.modal},s?"p-dialog-".concat(s):""]},root:function(e){var n=e.props,i=e.instance;return["p-dialog p-component",{"p-dialog-maximized":n.maximizable&&i.maximized}]},header:"p-dialog-header",title:"p-dialog-title",headerActions:"p-dialog-header-actions",pcMaximizeButton:"p-dialog-maximize-button",pcCloseButton:"p-dialog-close-button",content:"p-dialog-content",footer:"p-dialog-footer"},Bi=he.extend({name:"dialog",style:Di,classes:Ti,inlineStyles:Vi}),Fi={name:"BaseDialog",extends:He,props:{header:{type:null,default:null},footer:{type:null,default:null},visible:{type:Boolean,default:!1},modal:{type:Boolean,default:null},contentStyle:{type:null,default:null},contentClass:{type:String,default:null},contentProps:{type:null,default:null},maximizable:{type:Boolean,default:!1},dismissableMask:{type:Boolean,default:!1},closable:{type:Boolean,default:!0},closeOnEscape:{type:Boolean,default:!0},showHeader:{type:Boolean,default:!0},blockScroll:{type:Boolean,default:!1},baseZIndex:{type:Number,default:0},autoZIndex:{type:Boolean,default:!0},position:{type:String,default:"center"},breakpoints:{type:Object,default:null},draggable:{type:Boolean,default:!0},keepInViewport:{type:Boolean,default:!0},minX:{type:Number,default:0},minY:{type:Number,default:0},appendTo:{type:[String,Object],default:"body"},closeIcon:{type:String,default:void 0},maximizeIcon:{type:String,default:void 0},minimizeIcon:{type:String,default:void 0},closeButtonProps:{type:Object,default:function(){return{severity:"secondary",text:!0,rounded:!0}}},maximizeButtonProps:{type:Object,default:function(){return{severity:"secondary",text:!0,rounded:!0}}},_instance:null},style:Bi,provide:function(){return{$pcDialog:this,$parentInstance:this}}},mn={name:"Dialog",extends:Fi,inheritAttrs:!1,emits:["update:visible","show","hide","after-hide","maximize","unmaximize","dragstart","dragend"],provide:function(){var e=this;return{dialogRef:Y(function(){return e._instance})}},data:function(){return{containerVisible:this.visible,maximized:!1,focusableMax:null,focusableClose:null,target:null}},documentKeydownListener:null,container:null,mask:null,content:null,headerContainer:null,footerContainer:null,maximizableButton:null,closeButton:null,styleElement:null,dragging:null,documentDragListener:null,documentDragEndListener:null,lastPageX:null,lastPageY:null,maskMouseDownTarget:null,updated:function(){this.visible&&(this.containerVisible=this.visible)},beforeUnmount:function(){this.unbindDocumentState(),this.unbindGlobalListeners(),this.destroyStyle(),this.mask&&this.autoZIndex&&Oe.clear(this.mask),this.container=null,this.mask=null},mounted:function(){this.breakpoints&&this.createStyle()},methods:{close:function(){this.$emit("update:visible",!1)},onEnter:function(){this.$emit("show"),this.target=document.activeElement,this.enableDocumentSettings(),this.bindGlobalListeners(),this.autoZIndex&&Oe.set("modal",this.mask,this.baseZIndex||this.$primevue.config.zIndex.modal)},onAfterEnter:function(){this.focus()},onBeforeLeave:function(){this.modal&&!this.isUnstyled&&Zn(this.mask,"p-overlay-mask-leave-active"),this.dragging&&this.documentDragEndListener&&this.documentDragEndListener()},onLeave:function(){this.$emit("hide"),ie(this.target),this.target=null,this.focusableClose=null,this.focusableMax=null},onAfterLeave:function(){this.autoZIndex&&Oe.clear(this.mask),this.containerVisible=!1,this.unbindDocumentState(),this.unbindGlobalListeners(),this.$emit("after-hide")},onMaskMouseDown:function(e){this.maskMouseDownTarget=e.target},onMaskMouseUp:function(){this.dismissableMask&&this.modal&&this.mask===this.maskMouseDownTarget&&this.close()},focus:function(){var e=function(s){return s&&s.querySelector("[autofocus]")},n=this.$slots.footer&&e(this.footerContainer);n||(n=this.$slots.header&&e(this.headerContainer),n||(n=this.$slots.default&&e(this.content),n||(this.maximizable?(this.focusableMax=!0,n=this.maximizableButton):(this.focusableClose=!0,n=this.closeButton)))),n&&ie(n,{focusVisible:!0})},maximize:function(e){this.maximized?(this.maximized=!1,this.$emit("unmaximize",e)):(this.maximized=!0,this.$emit("maximize",e)),this.modal||(this.maximized?Kt():Ht())},enableDocumentSettings:function(){(this.modal||!this.modal&&this.blockScroll||this.maximizable&&this.maximized)&&Kt()},unbindDocumentState:function(){(this.modal||!this.modal&&this.blockScroll||this.maximizable&&this.maximized)&&Ht()},onKeyDown:function(e){e.code==="Escape"&&this.closeOnEscape&&!e.isComposing&&this.close()},bindDocumentKeyDownListener:function(){this.documentKeydownListener||(this.documentKeydownListener=this.onKeyDown.bind(this),window.document.addEventListener("keydown",this.documentKeydownListener))},unbindDocumentKeyDownListener:function(){this.documentKeydownListener&&(window.document.removeEventListener("keydown",this.documentKeydownListener),this.documentKeydownListener=null)},containerRef:function(e){this.container=e},maskRef:function(e){this.mask=e},contentRef:function(e){this.content=e},headerContainerRef:function(e){this.headerContainer=e},footerContainerRef:function(e){this.footerContainer=e},maximizableRef:function(e){this.maximizableButton=e?e.$el:void 0},closeButtonRef:function(e){this.closeButton=e?e.$el:void 0},createStyle:function(){if(!this.styleElement&&!this.isUnstyled){var e;this.styleElement=document.createElement("style"),this.styleElement.type="text/css",Wn(this.styleElement,"nonce",(e=this.$primevue)===null||e===void 0||(e=e.config)===null||e===void 0||(e=e.csp)===null||e===void 0?void 0:e.nonce),document.head.appendChild(this.styleElement);var n="";for(var i in this.breakpoints)n+=`
                        @media screen and (max-width: `.concat(i,`) {
                            .p-dialog[`).concat(this.$attrSelector,`] {
                                width: `).concat(this.breakpoints[i],` !important;
                            }
                        }
                    `);this.styleElement.innerHTML=n}},destroyStyle:function(){this.styleElement&&(document.head.removeChild(this.styleElement),this.styleElement=null)},initDrag:function(e){e.target.closest("div").getAttribute("data-pc-section")!=="headeractions"&&this.draggable&&(this.dragging=!0,this.lastPageX=e.pageX,this.lastPageY=e.pageY,this.container.style.margin="0",document.body.setAttribute("data-p-unselectable-text","true"),!this.isUnstyled&&rn(document.body,{"user-select":"none"}),this.$emit("dragstart",e))},bindGlobalListeners:function(){this.draggable&&(this.bindDocumentDragListener(),this.bindDocumentDragEndListener()),this.closeOnEscape&&this.bindDocumentKeyDownListener()},unbindGlobalListeners:function(){this.unbindDocumentDragListener(),this.unbindDocumentDragEndListener(),this.unbindDocumentKeyDownListener()},bindDocumentDragListener:function(){var e=this;this.documentDragListener=function(n){if(e.dragging){var i=an(e.container),s=Un(e.container),o=n.pageX-e.lastPageX,c=n.pageY-e.lastPageY,p=e.container.getBoundingClientRect(),m=p.left+o,g=p.top+c,h=Gn(),v=getComputedStyle(e.container),S=parseFloat(v.marginLeft),C=parseFloat(v.marginTop);e.container.style.position="fixed",e.keepInViewport?(m>=e.minX&&m+i<h.width&&(e.lastPageX=n.pageX,e.container.style.left=m-S+"px"),g>=e.minY&&g+s<h.height&&(e.lastPageY=n.pageY,e.container.style.top=g-C+"px")):(e.lastPageX=n.pageX,e.container.style.left=m-S+"px",e.lastPageY=n.pageY,e.container.style.top=g-C+"px")}},window.document.addEventListener("mousemove",this.documentDragListener)},unbindDocumentDragListener:function(){this.documentDragListener&&(window.document.removeEventListener("mousemove",this.documentDragListener),this.documentDragListener=null)},bindDocumentDragEndListener:function(){var e=this;this.documentDragEndListener=function(n){e.dragging&&(e.dragging=!1,document.body.removeAttribute("data-p-unselectable-text"),!e.isUnstyled&&(document.body.style["user-select"]=""),e.$emit("dragend",n))},window.document.addEventListener("mouseup",this.documentDragEndListener)},unbindDocumentDragEndListener:function(){this.documentDragEndListener&&(window.document.removeEventListener("mouseup",this.documentDragEndListener),this.documentDragEndListener=null)}},computed:{maximizeIconComponent:function(){return this.maximized?this.minimizeIcon?"span":"WindowMinimizeIcon":this.maximizeIcon?"span":"WindowMaximizeIcon"},ariaLabelledById:function(){return this.header!=null||this.$attrs["aria-labelledby"]!==null?this.$id+"_header":null},closeAriaLabel:function(){return this.$primevue.config.locale.aria?this.$primevue.config.locale.aria.close:void 0},dataP:function(){return me({maximized:this.maximized,modal:this.modal})}},directives:{ripple:vt,focustrap:Mi},components:{Button:Nn,Portal:yt,WindowMinimizeIcon:fn,WindowMaximizeIcon:pn,TimesIcon:et}};function De(t){"@babel/helpers - typeof";return De=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},De(t)}function Nt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function Ut(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Nt(Object(n),!0).forEach(function(i){Ri(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Nt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function Ri(t,e,n){return(e=ji(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function ji(t){var e=Ki(t,"string");return De(e)=="symbol"?e:e+""}function Ki(t,e){if(De(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(De(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Hi=["data-p"],Ni=["aria-labelledby","aria-modal","data-p"],Ui=["id"],Gi=["data-p"];function Wi(t,e,n,i,s,o){var c=ae("Button"),p=ae("Portal"),m=ht("focustrap");return u(),G(p,{appendTo:t.appendTo},{default:ne(function(){return[s.containerVisible?(u(),d("div",w({key:0,ref:o.maskRef,class:t.cx("mask"),style:t.sx("mask",!0,{position:t.position,modal:t.modal}),onMousedown:e[1]||(e[1]=function(){return o.onMaskMouseDown&&o.onMaskMouseDown.apply(o,arguments)}),onMouseup:e[2]||(e[2]=function(){return o.onMaskMouseUp&&o.onMaskMouseUp.apply(o,arguments)}),"data-p":o.dataP},t.ptm("mask")),[H(gt,w({name:"p-dialog",onEnter:o.onEnter,onAfterEnter:o.onAfterEnter,onBeforeLeave:o.onBeforeLeave,onLeave:o.onLeave,onAfterLeave:o.onAfterLeave,appear:""},t.ptm("transition")),{default:ne(function(){return[t.visible?Se((u(),d("div",w({key:0,ref:o.containerRef,class:t.cx("root"),style:t.sx("root"),role:"dialog","aria-labelledby":o.ariaLabelledById,"aria-modal":t.modal,"data-p":o.dataP},t.ptmi("root")),[t.$slots.container?P(t.$slots,"container",{key:0,closeCallback:o.close,maximizeCallback:function(h){return o.maximize(h)},initDragCallback:o.initDrag}):(u(),d(q,{key:1},[t.showHeader?(u(),d("div",w({key:0,ref:o.headerContainerRef,class:t.cx("header"),onMousedown:e[0]||(e[0]=function(){return o.initDrag&&o.initDrag.apply(o,arguments)})},t.ptm("header")),[P(t.$slots,"header",{class:ee(t.cx("title"))},function(){return[t.header?(u(),d("span",w({key:0,id:o.ariaLabelledById,class:t.cx("title")},t.ptm("title")),y(t.header),17,Ui)):b("",!0)]}),f("div",w({class:t.cx("headerActions")},t.ptm("headerActions")),[t.maximizable?P(t.$slots,"maximizebutton",{key:0,maximized:s.maximized,maximizeCallback:function(h){return o.maximize(h)}},function(){return[H(c,w({ref:o.maximizableRef,autofocus:s.focusableMax,class:t.cx("pcMaximizeButton"),onClick:o.maximize,tabindex:t.maximizable?"0":"-1",unstyled:t.unstyled},t.maximizeButtonProps,{pt:t.ptm("pcMaximizeButton"),"data-pc-group-section":"headericon"}),{icon:ne(function(g){return[P(t.$slots,"maximizeicon",{maximized:s.maximized},function(){return[(u(),G(Ie(o.maximizeIconComponent),w({class:[g.class,s.maximized?t.minimizeIcon:t.maximizeIcon]},t.ptm("pcMaximizeButton").icon),null,16,["class"]))]})]}),_:3},16,["autofocus","class","onClick","tabindex","unstyled","pt"])]}):b("",!0),t.closable?P(t.$slots,"closebutton",{key:1,closeCallback:o.close},function(){return[H(c,w({ref:o.closeButtonRef,autofocus:s.focusableClose,class:t.cx("pcCloseButton"),onClick:o.close,"aria-label":o.closeAriaLabel,unstyled:t.unstyled},t.closeButtonProps,{pt:t.ptm("pcCloseButton"),"data-pc-group-section":"headericon"}),{icon:ne(function(g){return[P(t.$slots,"closeicon",{},function(){return[(u(),G(Ie(t.closeIcon?"span":"TimesIcon"),w({class:[t.closeIcon,g.class]},t.ptm("pcCloseButton").icon),null,16,["class"]))]})]}),_:3},16,["autofocus","class","onClick","aria-label","unstyled","pt"])]}):b("",!0)],16)],16)):b("",!0),f("div",w({ref:o.contentRef,class:[t.cx("content"),t.contentClass],style:t.contentStyle,"data-p":o.dataP},Ut(Ut({},t.contentProps),t.ptm("content"))),[P(t.$slots,"default")],16,Gi),t.footer||t.$slots.footer?(u(),d("div",w({key:1,ref:o.footerContainerRef,class:t.cx("footer")},t.ptm("footer")),[P(t.$slots,"footer",{},function(){return[F(y(t.footer),1)]})],16)):b("",!0)],64))],16,Ni)),[[m,{disabled:!t.modal}]]):b("",!0)]}),_:3},16,["onEnter","onAfterEnter","onBeforeLeave","onLeave","onAfterLeave"])],16,Hi)):b("",!0)]}),_:3},8,["appendTo"])}mn.render=Wi;function Ve(t){"@babel/helpers - typeof";return Ve=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Ve(t)}function Zi(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}function Yi(t,e){for(var n=0;n<e.length;n++){var i=e[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(t,Ji(i.key),i)}}function Xi(t,e,n){return e&&Yi(t.prototype,e),Object.defineProperty(t,"prototype",{writable:!1}),t}function Ji(t){var e=Qi(t,"string");return Ve(e)=="symbol"?e:e+""}function Qi(t,e){if(Ve(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Ve(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return String(t)}var qi=(function(){function t(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:function(){};Zi(this,t),this.element=e,this.listener=n}return Xi(t,[{key:"bindScrollListener",value:function(){this.scrollableParents=Yn(this.element);for(var n=0;n<this.scrollableParents.length;n++)this.scrollableParents[n].addEventListener("scroll",this.listener)}},{key:"unbindScrollListener",value:function(){if(this.scrollableParents)for(var n=0;n<this.scrollableParents.length;n++)this.scrollableParents[n].removeEventListener("scroll",this.listener)}},{key:"destroy",value:function(){this.unbindScrollListener(),this.element=null,this.listener=null,this.scrollableParents=null}}])})(),hn={name:"ChevronDownIcon",extends:Ke};function eo(t){return oo(t)||io(t)||no(t)||to()}function to(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function no(t,e){if(t){if(typeof t=="string")return pt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?pt(t,e):void 0}}function io(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function oo(t){if(Array.isArray(t))return pt(t)}function pt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function so(t,e,n,i,s,o){return u(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),eo(e[0]||(e[0]=[f("path",{d:"M7.01744 10.398C6.91269 10.3985 6.8089 10.378 6.71215 10.3379C6.61541 10.2977 6.52766 10.2386 6.45405 10.1641L1.13907 4.84913C1.03306 4.69404 0.985221 4.5065 1.00399 4.31958C1.02276 4.13266 1.10693 3.95838 1.24166 3.82747C1.37639 3.69655 1.55301 3.61742 1.74039 3.60402C1.92777 3.59062 2.11386 3.64382 2.26584 3.75424L7.01744 8.47394L11.769 3.75424C11.9189 3.65709 12.097 3.61306 12.2748 3.62921C12.4527 3.64535 12.6199 3.72073 12.7498 3.84328C12.8797 3.96582 12.9647 4.12842 12.9912 4.30502C13.0177 4.48162 12.9841 4.662 12.8958 4.81724L7.58083 10.1322C7.50996 10.2125 7.42344 10.2775 7.32656 10.3232C7.22968 10.3689 7.12449 10.3944 7.01744 10.398Z",fill:"currentColor"},null,-1)])),16)}hn.render=so;var gn={name:"TimesCircleIcon",extends:Ke};function ao(t){return co(t)||uo(t)||lo(t)||ro()}function ro(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function lo(t,e){if(t){if(typeof t=="string")return ft(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ft(t,e):void 0}}function uo(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function co(t){if(Array.isArray(t))return ft(t)}function ft(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function po(t,e,n,i,s,o){return u(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),ao(e[0]||(e[0]=[f("path",{"fill-rule":"evenodd","clip-rule":"evenodd",d:"M7 14C5.61553 14 4.26215 13.5895 3.11101 12.8203C1.95987 12.0511 1.06266 10.9579 0.532846 9.67879C0.00303296 8.3997 -0.13559 6.99224 0.134506 5.63437C0.404603 4.2765 1.07129 3.02922 2.05026 2.05026C3.02922 1.07129 4.2765 0.404603 5.63437 0.134506C6.99224 -0.13559 8.3997 0.00303296 9.67879 0.532846C10.9579 1.06266 12.0511 1.95987 12.8203 3.11101C13.5895 4.26215 14 5.61553 14 7C14 8.85652 13.2625 10.637 11.9497 11.9497C10.637 13.2625 8.85652 14 7 14ZM7 1.16667C5.84628 1.16667 4.71846 1.50879 3.75918 2.14976C2.79989 2.79074 2.05222 3.70178 1.61071 4.76768C1.16919 5.83358 1.05367 7.00647 1.27876 8.13803C1.50384 9.26958 2.05941 10.309 2.87521 11.1248C3.69102 11.9406 4.73042 12.4962 5.86198 12.7212C6.99353 12.9463 8.16642 12.8308 9.23232 12.3893C10.2982 11.9478 11.2093 11.2001 11.8502 10.2408C12.4912 9.28154 12.8333 8.15373 12.8333 7C12.8333 5.45291 12.2188 3.96918 11.1248 2.87521C10.0308 1.78125 8.5471 1.16667 7 1.16667ZM4.66662 9.91668C4.58998 9.91704 4.51404 9.90209 4.44325 9.87271C4.37246 9.84333 4.30826 9.8001 4.2544 9.74557C4.14516 9.6362 4.0838 9.48793 4.0838 9.33335C4.0838 9.17876 4.14516 9.0305 4.2544 8.92113L6.17553 7L4.25443 5.07891C4.15139 4.96832 4.09529 4.82207 4.09796 4.67094C4.10063 4.51982 4.16185 4.37563 4.26872 4.26876C4.3756 4.16188 4.51979 4.10066 4.67091 4.09799C4.82204 4.09532 4.96829 4.15142 5.07887 4.25446L6.99997 6.17556L8.92106 4.25446C9.03164 4.15142 9.1779 4.09532 9.32903 4.09799C9.48015 4.10066 9.62434 4.16188 9.73121 4.26876C9.83809 4.37563 9.89931 4.51982 9.90198 4.67094C9.90464 4.82207 9.84855 4.96832 9.74551 5.07891L7.82441 7L9.74554 8.92113C9.85478 9.0305 9.91614 9.17876 9.91614 9.33335C9.91614 9.48793 9.85478 9.6362 9.74554 9.74557C9.69168 9.8001 9.62748 9.84333 9.55669 9.87271C9.4859 9.90209 9.40996 9.91704 9.33332 9.91668C9.25668 9.91704 9.18073 9.90209 9.10995 9.87271C9.03916 9.84333 8.97495 9.8001 8.9211 9.74557L6.99997 7.82444L5.07884 9.74557C5.02499 9.8001 4.96078 9.84333 4.88999 9.87271C4.81921 9.90209 4.74326 9.91704 4.66662 9.91668Z",fill:"currentColor"},null,-1)])),16)}gn.render=po;var fo=`
    .p-chip {
        display: inline-flex;
        align-items: center;
        background: dt('chip.background');
        color: dt('chip.color');
        border-radius: dt('chip.border.radius');
        padding-block: dt('chip.padding.y');
        padding-inline: dt('chip.padding.x');
        gap: dt('chip.gap');
    }

    .p-chip-icon {
        color: dt('chip.icon.color');
        font-size: dt('chip.icon.size');
        width: dt('chip.icon.size');
        height: dt('chip.icon.size');
    }

    .p-chip-image {
        border-radius: 50%;
        width: dt('chip.image.width');
        height: dt('chip.image.height');
        margin-inline-start: calc(-1 * dt('chip.padding.y'));
    }

    .p-chip:has(.p-chip-remove-icon) {
        padding-inline-end: dt('chip.padding.y');
    }

    .p-chip:has(.p-chip-image) {
        padding-block-start: calc(dt('chip.padding.y') / 2);
        padding-block-end: calc(dt('chip.padding.y') / 2);
    }

    .p-chip-remove-icon {
        cursor: pointer;
        font-size: dt('chip.remove.icon.size');
        width: dt('chip.remove.icon.size');
        height: dt('chip.remove.icon.size');
        color: dt('chip.remove.icon.color');
        border-radius: 50%;
        transition:
            outline-color dt('chip.transition.duration'),
            box-shadow dt('chip.transition.duration');
        outline-color: transparent;
    }

    .p-chip-remove-icon:focus-visible {
        box-shadow: dt('chip.remove.icon.focus.ring.shadow');
        outline: dt('chip.remove.icon.focus.ring.width') dt('chip.remove.icon.focus.ring.style') dt('chip.remove.icon.focus.ring.color');
        outline-offset: dt('chip.remove.icon.focus.ring.offset');
    }
`,mo={root:"p-chip p-component",image:"p-chip-image",icon:"p-chip-icon",label:"p-chip-label",removeIcon:"p-chip-remove-icon"},ho=he.extend({name:"chip",style:fo,classes:mo}),go={name:"BaseChip",extends:He,props:{label:{type:[String,Number],default:null},icon:{type:String,default:null},image:{type:String,default:null},removable:{type:Boolean,default:!1},removeIcon:{type:String,default:void 0}},style:ho,provide:function(){return{$pcChip:this,$parentInstance:this}}},vn={name:"Chip",extends:go,inheritAttrs:!1,emits:["remove"],data:function(){return{visible:!0}},methods:{onKeydown:function(e){(e.key==="Enter"||e.key==="Backspace")&&this.close(e)},close:function(e){this.visible=!1,this.$emit("remove",e)}},computed:{dataP:function(){return me({removable:this.removable})}},components:{TimesCircleIcon:gn}},vo=["aria-label","data-p"],yo=["src"];function bo(t,e,n,i,s,o){return s.visible?(u(),d("div",w({key:0,class:t.cx("root"),"aria-label":t.label},t.ptmi("root"),{"data-p":o.dataP}),[P(t.$slots,"default",{},function(){return[t.image?(u(),d("img",w({key:0,src:t.image},t.ptm("image"),{class:t.cx("image")}),null,16,yo)):t.$slots.icon?(u(),G(Ie(t.$slots.icon),w({key:1,class:t.cx("icon")},t.ptm("icon")),null,16,["class"])):t.icon?(u(),d("span",w({key:2,class:[t.cx("icon"),t.icon]},t.ptm("icon")),null,16)):b("",!0),t.label!==null?(u(),d("div",w({key:3,class:t.cx("label")},t.ptm("label")),y(t.label),17)):b("",!0)]}),t.removable?P(t.$slots,"removeicon",{key:0,removeCallback:o.close,keydownCallback:o.onKeydown},function(){return[(u(),G(Ie(t.removeIcon?"span":"TimesCircleIcon"),w({class:[t.cx("removeIcon"),t.removeIcon],onClick:o.close,onKeydown:o.onKeydown},t.ptm("removeIcon")),null,16,["class","onClick","onKeydown"]))]}):b("",!0)],16,vo)):b("",!0)}vn.render=bo;var wo={name:"BaseEditableHolder",extends:He,emits:["update:modelValue","value-change"],props:{modelValue:{type:null,default:void 0},defaultValue:{type:null,default:void 0},name:{type:String,default:void 0},invalid:{type:Boolean,default:void 0},disabled:{type:Boolean,default:!1},formControl:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0},$pcForm:{default:void 0},$pcFormField:{default:void 0}},data:function(){return{d_value:this.defaultValue!==void 0?this.defaultValue:this.modelValue}},watch:{modelValue:{deep:!0,handler:function(e){this.d_value=e}},defaultValue:function(e){this.d_value=e},$formName:{immediate:!0,handler:function(e){var n,i;this.formField=((n=this.$pcForm)===null||n===void 0||(i=n.register)===null||i===void 0?void 0:i.call(n,e,this.$formControl))||{}}},$formControl:{immediate:!0,handler:function(e){var n,i;this.formField=((n=this.$pcForm)===null||n===void 0||(i=n.register)===null||i===void 0?void 0:i.call(n,this.$formName,e))||{}}},$formDefaultValue:{immediate:!0,handler:function(e){this.d_value!==e&&(this.d_value=e)}},$formValue:{immediate:!1,handler:function(e){var n;(n=this.$pcForm)!==null&&n!==void 0&&n.getFieldState(this.$formName)&&e!==this.d_value&&(this.d_value=e)}}},formField:{},methods:{writeValue:function(e,n){var i,s;this.controlled&&(this.d_value=e,this.$emit("update:modelValue",e)),this.$emit("value-change",e),(i=(s=this.formField).onChange)===null||i===void 0||i.call(s,{originalEvent:n,value:e})},findNonEmpty:function(){for(var e=arguments.length,n=new Array(e),i=0;i<e;i++)n[i]=arguments[i];return n.find(fe)}},computed:{$filled:function(){return fe(this.d_value)},$invalid:function(){var e,n;return!this.$formNovalidate&&this.findNonEmpty(this.invalid,(e=this.$pcFormField)===null||e===void 0||(e=e.$field)===null||e===void 0?void 0:e.invalid,(n=this.$pcForm)===null||n===void 0||(n=n.getFieldState(this.$formName))===null||n===void 0?void 0:n.invalid)},$formName:function(){var e;return this.$formNovalidate?void 0:this.name||((e=this.$formControl)===null||e===void 0?void 0:e.name)},$formControl:function(){var e;return this.formControl||((e=this.$pcFormField)===null||e===void 0?void 0:e.formControl)},$formNovalidate:function(){var e;return(e=this.$formControl)===null||e===void 0?void 0:e.novalidate},$formDefaultValue:function(){var e,n;return this.findNonEmpty(this.d_value,(e=this.$pcFormField)===null||e===void 0?void 0:e.initialValue,(n=this.$pcForm)===null||n===void 0||(n=n.initialValues)===null||n===void 0?void 0:n[this.$formName])},$formValue:function(){var e,n;return this.findNonEmpty((e=this.$pcFormField)===null||e===void 0||(e=e.$field)===null||e===void 0?void 0:e.value,(n=this.$pcForm)===null||n===void 0||(n=n.getFieldState(this.$formName))===null||n===void 0?void 0:n.value)},controlled:function(){return this.$inProps.hasOwnProperty("modelValue")||!this.$inProps.hasOwnProperty("modelValue")&&!this.$inProps.hasOwnProperty("defaultValue")},filled:function(){return this.$filled}}},yn={name:"BaseInput",extends:wo,props:{size:{type:String,default:null},fluid:{type:Boolean,default:null},variant:{type:String,default:null}},inject:{$parentInstance:{default:void 0},$pcFluid:{default:void 0}},computed:{$variant:function(){var e;return(e=this.variant)!==null&&e!==void 0?e:this.$primevue.config.inputStyle||this.$primevue.config.inputVariant},$fluid:function(){var e;return(e=this.fluid)!==null&&e!==void 0?e:!!this.$pcFluid},hasFluid:function(){return this.$fluid}}},Co=`
    .p-inputtext {
        font-family: inherit;
        font-feature-settings: inherit;
        font-size: 1rem;
        color: dt('inputtext.color');
        background: dt('inputtext.background');
        padding-block: dt('inputtext.padding.y');
        padding-inline: dt('inputtext.padding.x');
        border: 1px solid dt('inputtext.border.color');
        transition:
            background dt('inputtext.transition.duration'),
            color dt('inputtext.transition.duration'),
            border-color dt('inputtext.transition.duration'),
            outline-color dt('inputtext.transition.duration'),
            box-shadow dt('inputtext.transition.duration');
        appearance: none;
        border-radius: dt('inputtext.border.radius');
        outline-color: transparent;
        box-shadow: dt('inputtext.shadow');
    }

    .p-inputtext:enabled:hover {
        border-color: dt('inputtext.hover.border.color');
    }

    .p-inputtext:enabled:focus {
        border-color: dt('inputtext.focus.border.color');
        box-shadow: dt('inputtext.focus.ring.shadow');
        outline: dt('inputtext.focus.ring.width') dt('inputtext.focus.ring.style') dt('inputtext.focus.ring.color');
        outline-offset: dt('inputtext.focus.ring.offset');
    }

    .p-inputtext.p-invalid {
        border-color: dt('inputtext.invalid.border.color');
    }

    .p-inputtext.p-variant-filled {
        background: dt('inputtext.filled.background');
    }

    .p-inputtext.p-variant-filled:enabled:hover {
        background: dt('inputtext.filled.hover.background');
    }

    .p-inputtext.p-variant-filled:enabled:focus {
        background: dt('inputtext.filled.focus.background');
    }

    .p-inputtext:disabled {
        opacity: 1;
        background: dt('inputtext.disabled.background');
        color: dt('inputtext.disabled.color');
    }

    .p-inputtext::placeholder {
        color: dt('inputtext.placeholder.color');
    }

    .p-inputtext.p-invalid::placeholder {
        color: dt('inputtext.invalid.placeholder.color');
    }

    .p-inputtext-sm {
        font-size: dt('inputtext.sm.font.size');
        padding-block: dt('inputtext.sm.padding.y');
        padding-inline: dt('inputtext.sm.padding.x');
    }

    .p-inputtext-lg {
        font-size: dt('inputtext.lg.font.size');
        padding-block: dt('inputtext.lg.padding.y');
        padding-inline: dt('inputtext.lg.padding.x');
    }

    .p-inputtext-fluid {
        width: 100%;
    }
`,So={root:function(e){var n=e.instance,i=e.props;return["p-inputtext p-component",{"p-filled":n.$filled,"p-inputtext-sm p-inputfield-sm":i.size==="small","p-inputtext-lg p-inputfield-lg":i.size==="large","p-invalid":n.$invalid,"p-variant-filled":n.$variant==="filled","p-inputtext-fluid":n.$fluid}]}},Oo=he.extend({name:"inputtext",style:Co,classes:So}),Io={name:"BaseInputText",extends:yn,style:Oo,provide:function(){return{$pcInputText:this,$parentInstance:this}}};function Te(t){"@babel/helpers - typeof";return Te=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Te(t)}function ko(t,e,n){return(e=xo(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function xo(t){var e=$o(t,"string");return Te(e)=="symbol"?e:e+""}function $o(t,e){if(Te(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Te(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var bt={name:"InputText",extends:Io,inheritAttrs:!1,methods:{onInput:function(e){this.writeValue(e.target.value,e)}},computed:{attrs:function(){return w(this.ptmi("root",{context:{filled:this.$filled,disabled:this.disabled}}),this.formField)},dataP:function(){return me(ko({invalid:this.$invalid,fluid:this.$fluid,filled:this.$variant==="filled"},this.size,this.size))}}},zo=["value","name","disabled","aria-invalid","data-p"];function Lo(t,e,n,i,s,o){return u(),d("input",w({type:"text",class:t.cx("root"),value:t.d_value,name:t.name,disabled:t.disabled,"aria-invalid":t.$invalid||void 0,"data-p":o.dataP,onInput:e[0]||(e[0]=function(){return o.onInput&&o.onInput.apply(o,arguments)})},o.attrs),null,16,zo)}bt.render=Lo;var Po=Xn(),_o=`
    .p-virtualscroller-loader {
        background: dt('virtualscroller.loader.mask.background');
        color: dt('virtualscroller.loader.mask.color');
    }

    .p-virtualscroller-loading-icon {
        font-size: dt('virtualscroller.loader.icon.size');
        width: dt('virtualscroller.loader.icon.size');
        height: dt('virtualscroller.loader.icon.size');
    }
`,Eo=`
.p-virtualscroller {
    position: relative;
    overflow: auto;
    contain: strict;
    transform: translateZ(0);
    will-change: scroll-position;
    outline: 0 none;
}

.p-virtualscroller-content {
    position: absolute;
    top: 0;
    left: 0;
    min-height: 100%;
    min-width: 100%;
    will-change: transform;
}

.p-virtualscroller-spacer {
    position: absolute;
    top: 0;
    left: 0;
    height: 1px;
    width: 1px;
    transform-origin: 0 0;
    pointer-events: none;
}

.p-virtualscroller-loader {
    position: sticky;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
}

.p-virtualscroller-loader-mask {
    display: flex;
    align-items: center;
    justify-content: center;
}

.p-virtualscroller-horizontal > .p-virtualscroller-content {
    display: flex;
}

.p-virtualscroller-inline .p-virtualscroller-content {
    position: static;
}

.p-virtualscroller .p-virtualscroller-loading {
    transform: none !important;
    min-height: 0;
    position: sticky;
    inset-block-start: 0;
    inset-inline-start: 0;
}
`,Gt=he.extend({name:"virtualscroller",css:Eo,style:_o}),Mo={name:"BaseVirtualScroller",extends:He,props:{id:{type:String,default:null},style:null,class:null,items:{type:Array,default:null},itemSize:{type:[Number,Array],default:0},scrollHeight:null,scrollWidth:null,orientation:{type:String,default:"vertical"},numToleratedItems:{type:Number,default:null},delay:{type:Number,default:0},resizeDelay:{type:Number,default:10},lazy:{type:Boolean,default:!1},disabled:{type:Boolean,default:!1},loaderDisabled:{type:Boolean,default:!1},columns:{type:Array,default:null},loading:{type:Boolean,default:!1},showSpacer:{type:Boolean,default:!0},showLoader:{type:Boolean,default:!1},tabindex:{type:Number,default:0},inline:{type:Boolean,default:!1},step:{type:Number,default:0},appendOnly:{type:Boolean,default:!1},autoSize:{type:Boolean,default:!1}},style:Gt,provide:function(){return{$pcVirtualScroller:this,$parentInstance:this}},beforeMount:function(){var e;Gt.loadCSS({nonce:(e=this.$primevueConfig)===null||e===void 0||(e=e.csp)===null||e===void 0?void 0:e.nonce})}};function Be(t){"@babel/helpers - typeof";return Be=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Be(t)}function Wt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function Me(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Wt(Object(n),!0).forEach(function(i){bn(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Wt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function bn(t,e,n){return(e=Ao(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Ao(t){var e=Do(t,"string");return Be(e)=="symbol"?e:e+""}function Do(t,e){if(Be(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Be(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var wn={name:"VirtualScroller",extends:Mo,inheritAttrs:!1,emits:["update:numToleratedItems","scroll","scroll-index-change","lazy-load"],data:function(){var e=this.isBoth();return{first:e?{rows:0,cols:0}:0,last:e?{rows:0,cols:0}:0,page:e?{rows:0,cols:0}:0,numItemsInViewport:e?{rows:0,cols:0}:0,lastScrollPos:e?{top:0,left:0}:0,d_numToleratedItems:this.numToleratedItems,d_loading:this.loading,loaderArr:[],spacerStyle:{},contentStyle:{}}},element:null,content:null,lastScrollPos:null,scrollTimeout:null,resizeTimeout:null,defaultWidth:0,defaultHeight:0,defaultContentWidth:0,defaultContentHeight:0,isRangeChanged:!1,lazyLoadState:{},resizeListener:null,resizeObserver:null,initialized:!1,watch:{numToleratedItems:function(e){this.d_numToleratedItems=e},loading:function(e,n){this.lazy&&e!==n&&e!==this.d_loading&&(this.d_loading=e)},items:{handler:function(e,n){(!n||n.length!==(e||[]).length)&&(this.init(),this.calculateAutoSize())},deep:!0},itemSize:function(){this.init(),this.calculateAutoSize()},orientation:function(){this.lastScrollPos=this.isBoth()?{top:0,left:0}:0},scrollHeight:function(){this.init(),this.calculateAutoSize()},scrollWidth:function(){this.init(),this.calculateAutoSize()}},mounted:function(){this.viewInit(),this.lastScrollPos=this.isBoth()?{top:0,left:0}:0,this.lazyLoadState=this.lazyLoadState||{}},updated:function(){!this.initialized&&this.viewInit()},unmounted:function(){this.unbindResizeListener(),this.initialized=!1},methods:{viewInit:function(){Ft(this.element)&&(this.setContentEl(this.content),this.init(),this.calculateAutoSize(),this.defaultWidth=Le(this.element),this.defaultHeight=Pe(this.element),this.defaultContentWidth=Le(this.content),this.defaultContentHeight=Pe(this.content),this.initialized=!0),this.element&&this.bindResizeListener()},init:function(){this.disabled||(this.setSize(),this.calculateOptions(),this.setSpacerSize())},isVertical:function(){return this.orientation==="vertical"},isHorizontal:function(){return this.orientation==="horizontal"},isBoth:function(){return this.orientation==="both"},scrollTo:function(e){this.element&&this.element.scrollTo(e)},scrollToIndex:function(e){var n=this,i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"auto",s=this.isBoth(),o=this.isHorizontal(),c=s?e.every(function(O){return O>-1}):e>-1;if(c){var p=this.first,m=this.element,g=m.scrollTop,h=g===void 0?0:g,v=m.scrollLeft,S=v===void 0?0:v,C=this.calculateNumItems(),k=C.numToleratedItems,L=this.getContentPosition(),_=this.itemSize,M=function(){var D=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,K=arguments.length>1?arguments[1]:void 0;return D<=K?0:D},A=function(D,K,J){return D*K+J},R=function(){var D=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,K=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;return n.scrollTo({left:D,top:K,behavior:i})},x=s?{rows:0,cols:0}:0,B=!1,z=!1;s?(x={rows:M(e[0],k[0]),cols:M(e[1],k[1])},R(A(x.cols,_[1],L.left),A(x.rows,_[0],L.top)),z=this.lastScrollPos.top!==h||this.lastScrollPos.left!==S,B=x.rows!==p.rows||x.cols!==p.cols):(x=M(e,k),o?R(A(x,_,L.left),h):R(S,A(x,_,L.top)),z=this.lastScrollPos!==(o?S:h),B=x!==p),this.isRangeChanged=B,z&&(this.first=x)}},scrollInView:function(e,n){var i=this,s=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"auto";if(n){var o=this.isBoth(),c=this.isHorizontal(),p=o?e.every(function(_){return _>-1}):e>-1;if(p){var m=this.getRenderedRange(),g=m.first,h=m.viewport,v=function(){var M=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,A=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;return i.scrollTo({left:M,top:A,behavior:s})},S=n==="to-start",C=n==="to-end";if(S){if(o)h.first.rows-g.rows>e[0]?v(h.first.cols*this.itemSize[1],(h.first.rows-1)*this.itemSize[0]):h.first.cols-g.cols>e[1]&&v((h.first.cols-1)*this.itemSize[1],h.first.rows*this.itemSize[0]);else if(h.first-g>e){var k=(h.first-1)*this.itemSize;c?v(k,0):v(0,k)}}else if(C){if(o)h.last.rows-g.rows<=e[0]+1?v(h.first.cols*this.itemSize[1],(h.first.rows+1)*this.itemSize[0]):h.last.cols-g.cols<=e[1]+1&&v((h.first.cols+1)*this.itemSize[1],h.first.rows*this.itemSize[0]);else if(h.last-g<=e+1){var L=(h.first+1)*this.itemSize;c?v(L,0):v(0,L)}}}}else this.scrollToIndex(e,s)},getRenderedRange:function(){var e=function(v,S){return Math.floor(v/(S||v))},n=this.first,i=0;if(this.element){var s=this.isBoth(),o=this.isHorizontal(),c=this.element,p=c.scrollTop,m=c.scrollLeft;if(s)n={rows:e(p,this.itemSize[0]),cols:e(m,this.itemSize[1])},i={rows:n.rows+this.numItemsInViewport.rows,cols:n.cols+this.numItemsInViewport.cols};else{var g=o?m:p;n=e(g,this.itemSize),i=n+this.numItemsInViewport}}return{first:this.first,last:this.last,viewport:{first:n,last:i}}},calculateNumItems:function(){var e=this.isBoth(),n=this.isHorizontal(),i=this.itemSize,s=this.getContentPosition(),o=this.element?this.element.offsetWidth-s.left:0,c=this.element?this.element.offsetHeight-s.top:0,p=function(S,C){return Math.ceil(S/(C||S))},m=function(S){return Math.ceil(S/2)},g=e?{rows:p(c,i[0]),cols:p(o,i[1])}:p(n?o:c,i),h=this.d_numToleratedItems||(e?[m(g.rows),m(g.cols)]:m(g));return{numItemsInViewport:g,numToleratedItems:h}},calculateOptions:function(){var e=this,n=this.isBoth(),i=this.first,s=this.calculateNumItems(),o=s.numItemsInViewport,c=s.numToleratedItems,p=function(h,v,S){var C=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!1;return e.getLast(h+v+(h<S?2:3)*S,C)},m=n?{rows:p(i.rows,o.rows,c[0]),cols:p(i.cols,o.cols,c[1],!0)}:p(i,o,c);this.last=m,this.numItemsInViewport=o,this.d_numToleratedItems=c,this.$emit("update:numToleratedItems",this.d_numToleratedItems),this.showLoader&&(this.loaderArr=n?Array.from({length:o.rows}).map(function(){return Array.from({length:o.cols})}):Array.from({length:o})),this.lazy&&Promise.resolve().then(function(){var g;e.lazyLoadState={first:e.step?n?{rows:0,cols:i.cols}:0:i,last:Math.min(e.step?e.step:m,((g=e.items)===null||g===void 0?void 0:g.length)||0)},e.$emit("lazy-load",e.lazyLoadState)})},calculateAutoSize:function(){var e=this;this.autoSize&&!this.d_loading&&Promise.resolve().then(function(){if(e.content){var n=e.isBoth(),i=e.isHorizontal(),s=e.isVertical();e.content.style.minHeight=e.content.style.minWidth="auto",e.content.style.position="relative",e.element.style.contain="none";var o=[Le(e.element),Pe(e.element)],c=o[0],p=o[1];(n||i)&&(e.element.style.width=c<e.defaultWidth?c+"px":e.scrollWidth||e.defaultWidth+"px"),(n||s)&&(e.element.style.height=p<e.defaultHeight?p+"px":e.scrollHeight||e.defaultHeight+"px"),e.content.style.minHeight=e.content.style.minWidth="",e.content.style.position="",e.element.style.contain=""}})},getLast:function(){var e,n,i=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,s=arguments.length>1?arguments[1]:void 0;return this.items?Math.min(s?((e=this.columns||this.items[0])===null||e===void 0?void 0:e.length)||0:((n=this.items)===null||n===void 0?void 0:n.length)||0,i):0},getContentPosition:function(){if(this.content){var e=getComputedStyle(this.content),n=parseFloat(e.paddingLeft)+Math.max(parseFloat(e.left)||0,0),i=parseFloat(e.paddingRight)+Math.max(parseFloat(e.right)||0,0),s=parseFloat(e.paddingTop)+Math.max(parseFloat(e.top)||0,0),o=parseFloat(e.paddingBottom)+Math.max(parseFloat(e.bottom)||0,0);return{left:n,right:i,top:s,bottom:o,x:n+i,y:s+o}}return{left:0,right:0,top:0,bottom:0,x:0,y:0}},setSize:function(){var e=this;if(this.element){var n=this.isBoth(),i=this.isHorizontal(),s=this.element.parentElement,o=this.scrollWidth||"".concat(this.element.offsetWidth||s.offsetWidth,"px"),c=this.scrollHeight||"".concat(this.element.offsetHeight||s.offsetHeight,"px"),p=function(g,h){return e.element.style[g]=h};n||i?(p("height",c),p("width",o)):p("height",c)}},setSpacerSize:function(){var e=this,n=this.items;if(n){var i=this.isBoth(),s=this.isHorizontal(),o=this.getContentPosition(),c=function(m,g,h){var v=arguments.length>3&&arguments[3]!==void 0?arguments[3]:0;return e.spacerStyle=Me(Me({},e.spacerStyle),bn({},"".concat(m),(g||[]).length*h+v+"px"))};i?(c("height",n,this.itemSize[0],o.y),c("width",this.columns||n[1],this.itemSize[1],o.x)):s?c("width",this.columns||n,this.itemSize,o.x):c("height",n,this.itemSize,o.y)}},setContentPosition:function(e){var n=this;if(this.content&&!this.appendOnly){var i=this.isBoth(),s=this.isHorizontal(),o=e?e.first:this.first,c=function(h,v){return h*v},p=function(){var h=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,v=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;return n.contentStyle=Me(Me({},n.contentStyle),{transform:"translate3d(".concat(h,"px, ").concat(v,"px, 0)")})};if(i)p(c(o.cols,this.itemSize[1]),c(o.rows,this.itemSize[0]));else{var m=c(o,this.itemSize);s?p(m,0):p(0,m)}}},onScrollPositionChange:function(e){var n=this,i=e.target,s=this.isBoth(),o=this.isHorizontal(),c=this.getContentPosition(),p=function($,Z){return $?$>Z?$-Z:$:0},m=function($,Z){return Math.floor($/(Z||$))},g=function($,Z,oe,Q,N,se){return $<=N?N:se?oe-Q-N:Z+N-1},h=function($,Z,oe,Q,N,se,ge,xe){if($<=se)return 0;var V=Math.max(0,ge?$<Z?oe:$-se:$>Z?oe:$-2*se),$e=n.getLast(V,xe);return V>$e?$e-N:V},v=function($,Z,oe,Q,N,se){var ge=Z+Q+2*N;return $>=N&&(ge+=N+1),n.getLast(ge,se)},S=p(i.scrollTop,c.top),C=p(i.scrollLeft,c.left),k=s?{rows:0,cols:0}:0,L=this.last,_=!1,M=this.lastScrollPos;if(s){var A=this.lastScrollPos.top<=S,R=this.lastScrollPos.left<=C;if(!this.appendOnly||this.appendOnly&&(A||R)){var x={rows:m(S,this.itemSize[0]),cols:m(C,this.itemSize[1])},B={rows:g(x.rows,this.first.rows,this.last.rows,this.numItemsInViewport.rows,this.d_numToleratedItems[0],A),cols:g(x.cols,this.first.cols,this.last.cols,this.numItemsInViewport.cols,this.d_numToleratedItems[1],R)};k={rows:h(x.rows,B.rows,this.first.rows,this.last.rows,this.numItemsInViewport.rows,this.d_numToleratedItems[0],A),cols:h(x.cols,B.cols,this.first.cols,this.last.cols,this.numItemsInViewport.cols,this.d_numToleratedItems[1],R,!0)},L={rows:v(x.rows,k.rows,this.last.rows,this.numItemsInViewport.rows,this.d_numToleratedItems[0]),cols:v(x.cols,k.cols,this.last.cols,this.numItemsInViewport.cols,this.d_numToleratedItems[1],!0)},_=k.rows!==this.first.rows||L.rows!==this.last.rows||k.cols!==this.first.cols||L.cols!==this.last.cols||this.isRangeChanged,M={top:S,left:C}}}else{var z=o?C:S,O=this.lastScrollPos<=z;if(!this.appendOnly||this.appendOnly&&O){var D=m(z,this.itemSize),K=g(D,this.first,this.last,this.numItemsInViewport,this.d_numToleratedItems,O);k=h(D,K,this.first,this.last,this.numItemsInViewport,this.d_numToleratedItems,O),L=v(D,k,this.last,this.numItemsInViewport,this.d_numToleratedItems),_=k!==this.first||L!==this.last||this.isRangeChanged,M=z}}return{first:k,last:L,isRangeChanged:_,scrollPos:M}},onScrollChange:function(e){var n=this.onScrollPositionChange(e),i=n.first,s=n.last,o=n.isRangeChanged,c=n.scrollPos;if(o){var p={first:i,last:s};if(this.setContentPosition(p),this.first=i,this.last=s,this.lastScrollPos=c,this.$emit("scroll-index-change",p),this.lazy&&this.isPageChanged(i)){var m,g,h={first:this.step?Math.min(this.getPageByFirst(i)*this.step,(((m=this.items)===null||m===void 0?void 0:m.length)||0)-this.step):i,last:Math.min(this.step?(this.getPageByFirst(i)+1)*this.step:s,((g=this.items)===null||g===void 0?void 0:g.length)||0)},v=this.lazyLoadState.first!==h.first||this.lazyLoadState.last!==h.last;v&&this.$emit("lazy-load",h),this.lazyLoadState=h}}},onScroll:function(e){var n=this;if(this.$emit("scroll",e),this.delay){if(this.scrollTimeout&&clearTimeout(this.scrollTimeout),this.isPageChanged()){if(!this.d_loading&&this.showLoader){var i=this.onScrollPositionChange(e),s=i.isRangeChanged,o=s||(this.step?this.isPageChanged():!1);o&&(this.d_loading=!0)}this.scrollTimeout=setTimeout(function(){n.onScrollChange(e),n.d_loading&&n.showLoader&&(!n.lazy||n.loading===void 0)&&(n.d_loading=!1,n.page=n.getPageByFirst())},this.delay)}}else this.onScrollChange(e)},onResize:function(){var e=this;this.resizeTimeout&&clearTimeout(this.resizeTimeout),this.resizeTimeout=setTimeout(function(){if(Ft(e.element)){var n=e.isBoth(),i=e.isVertical(),s=e.isHorizontal(),o=[Le(e.element),Pe(e.element)],c=o[0],p=o[1],m=c!==e.defaultWidth,g=p!==e.defaultHeight,h=n?m||g:s?m:i?g:!1;h&&(e.d_numToleratedItems=e.numToleratedItems,e.defaultWidth=c,e.defaultHeight=p,e.defaultContentWidth=Le(e.content),e.defaultContentHeight=Pe(e.content),e.init())}},this.resizeDelay)},bindResizeListener:function(){var e=this;this.resizeListener||(this.resizeListener=this.onResize.bind(this),window.addEventListener("resize",this.resizeListener),window.addEventListener("orientationchange",this.resizeListener),this.resizeObserver=new ResizeObserver(function(){e.onResize()}),this.resizeObserver.observe(this.element))},unbindResizeListener:function(){this.resizeListener&&(window.removeEventListener("resize",this.resizeListener),window.removeEventListener("orientationchange",this.resizeListener),this.resizeListener=null),this.resizeObserver&&(this.resizeObserver.disconnect(),this.resizeObserver=null)},getOptions:function(e){var n=(this.items||[]).length,i=this.isBoth()?this.first.rows+e:this.first+e;return{index:i,count:n,first:i===0,last:i===n-1,even:i%2===0,odd:i%2!==0}},getLoaderOptions:function(e,n){var i=this.loaderArr.length;return Me({index:e,count:i,first:e===0,last:e===i-1,even:e%2===0,odd:e%2!==0},n)},getPageByFirst:function(e){return Math.floor(((e??this.first)+this.d_numToleratedItems*4)/(this.step||1))},isPageChanged:function(e){return this.step&&!this.lazy?this.page!==this.getPageByFirst(e??this.first):!0},setContentEl:function(e){this.content=e||this.content||un(this.element,'[data-pc-section="content"]')},elementRef:function(e){this.element=e},contentRef:function(e){this.content=e}},computed:{containerClass:function(){return["p-virtualscroller",this.class,{"p-virtualscroller-inline":this.inline,"p-virtualscroller-both p-both-scroll":this.isBoth(),"p-virtualscroller-horizontal p-horizontal-scroll":this.isHorizontal()}]},contentClass:function(){return["p-virtualscroller-content",{"p-virtualscroller-loading":this.d_loading}]},loaderClass:function(){return["p-virtualscroller-loader",{"p-virtualscroller-loader-mask":!this.$slots.loader}]},loadedItems:function(){var e=this;return this.items&&!this.d_loading?this.isBoth()?this.items.slice(this.appendOnly?0:this.first.rows,this.last.rows).map(function(n){return e.columns?n:n.slice(e.appendOnly?0:e.first.cols,e.last.cols)}):this.isHorizontal()&&this.columns?this.items:this.items.slice(this.appendOnly?0:this.first,this.last):[]},loadedRows:function(){return this.d_loading?this.loaderDisabled?this.loaderArr:[]:this.loadedItems},loadedColumns:function(){if(this.columns){var e=this.isBoth(),n=this.isHorizontal();if(e||n)return this.d_loading&&this.loaderDisabled?e?this.loaderArr[0]:this.loaderArr:this.columns.slice(e?this.first.cols:this.first,e?this.last.cols:this.last)}return this.columns}},components:{SpinnerIcon:ln}},Vo=["tabindex"];function To(t,e,n,i,s,o){var c=ae("SpinnerIcon");return t.disabled?(u(),d(q,{key:1},[P(t.$slots,"default"),P(t.$slots,"content",{items:t.items,rows:t.items,columns:o.loadedColumns})],64)):(u(),d("div",w({key:0,ref:o.elementRef,class:o.containerClass,tabindex:t.tabindex,style:t.style,onScroll:e[0]||(e[0]=function(){return o.onScroll&&o.onScroll.apply(o,arguments)})},t.ptmi("root")),[P(t.$slots,"content",{styleClass:o.contentClass,items:o.loadedItems,getItemOptions:o.getOptions,loading:s.d_loading,getLoaderOptions:o.getLoaderOptions,itemSize:t.itemSize,rows:o.loadedRows,columns:o.loadedColumns,contentRef:o.contentRef,spacerStyle:s.spacerStyle,contentStyle:s.contentStyle,vertical:o.isVertical(),horizontal:o.isHorizontal(),both:o.isBoth()},function(){return[f("div",w({ref:o.contentRef,class:o.contentClass,style:s.contentStyle},t.ptm("content")),[(u(!0),d(q,null,re(o.loadedItems,function(p,m){return P(t.$slots,"item",{key:m,item:p,options:o.getOptions(m)})}),128))],16)]}),t.showSpacer?(u(),d("div",w({key:0,class:"p-virtualscroller-spacer",style:s.spacerStyle},t.ptm("spacer")),null,16)):b("",!0),!t.loaderDisabled&&t.showLoader&&s.d_loading?(u(),d("div",w({key:1,class:o.loaderClass},t.ptm("loader")),[t.$slots&&t.$slots.loader?(u(!0),d(q,{key:0},re(s.loaderArr,function(p,m){return P(t.$slots,"loader",{key:m,options:o.getLoaderOptions(m,o.isBoth()&&{numCols:t.d_numItemsInViewport.cols})})}),128)):b("",!0),P(t.$slots,"loadingicon",{},function(){return[H(c,w({spin:"",class:"p-virtualscroller-loading-icon"},t.ptm("loadingIcon")),null,16)]})],16)):b("",!0)],16,Vo))}wn.render=To;var Bo=`
    .p-autocomplete {
        display: inline-flex;
    }

    .p-autocomplete-loader {
        position: absolute;
        top: 50%;
        margin-top: -0.5rem;
        inset-inline-end: dt('autocomplete.padding.x');
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-loader {
        inset-inline-end: calc(dt('autocomplete.dropdown.width') + dt('autocomplete.padding.x'));
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-input {
        flex: 1 1 auto;
        width: 1%;
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-input,
    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-input-multiple {
        border-start-end-radius: 0;
        border-end-end-radius: 0;
    }

    .p-autocomplete-dropdown {
        cursor: pointer;
        display: inline-flex;
        user-select: none;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        position: relative;
        width: dt('autocomplete.dropdown.width');
        border-start-end-radius: dt('autocomplete.dropdown.border.radius');
        border-end-end-radius: dt('autocomplete.dropdown.border.radius');
        background: dt('autocomplete.dropdown.background');
        border: 1px solid dt('autocomplete.dropdown.border.color');
        border-inline-start: 0 none;
        color: dt('autocomplete.dropdown.color');
        transition:
            background dt('autocomplete.transition.duration'),
            color dt('autocomplete.transition.duration'),
            border-color dt('autocomplete.transition.duration'),
            outline-color dt('autocomplete.transition.duration'),
            box-shadow dt('autocomplete.transition.duration');
        outline-color: transparent;
    }

    .p-autocomplete-dropdown:not(:disabled):hover {
        background: dt('autocomplete.dropdown.hover.background');
        border-color: dt('autocomplete.dropdown.hover.border.color');
        color: dt('autocomplete.dropdown.hover.color');
    }

    .p-autocomplete-dropdown:not(:disabled):active {
        background: dt('autocomplete.dropdown.active.background');
        border-color: dt('autocomplete.dropdown.active.border.color');
        color: dt('autocomplete.dropdown.active.color');
    }

    .p-autocomplete-dropdown:focus-visible {
        box-shadow: dt('autocomplete.dropdown.focus.ring.shadow');
        outline: dt('autocomplete.dropdown.focus.ring.width') dt('autocomplete.dropdown.focus.ring.style') dt('autocomplete.dropdown.focus.ring.color');
        outline-offset: dt('autocomplete.dropdown.focus.ring.offset');
    }

    .p-autocomplete-overlay {
        position: absolute;
        top: 0;
        left: 0;
        background: dt('autocomplete.overlay.background');
        color: dt('autocomplete.overlay.color');
        border: 1px solid dt('autocomplete.overlay.border.color');
        border-radius: dt('autocomplete.overlay.border.radius');
        box-shadow: dt('autocomplete.overlay.shadow');
        min-width: 100%;
    }

    .p-autocomplete-list-container {
        overflow: auto;
    }

    .p-autocomplete-list {
        margin: 0;
        list-style-type: none;
        display: flex;
        flex-direction: column;
        gap: dt('autocomplete.list.gap');
        padding: dt('autocomplete.list.padding');
    }

    .p-autocomplete-option {
        cursor: pointer;
        white-space: nowrap;
        position: relative;
        overflow: hidden;
        display: flex;
        align-items: center;
        padding: dt('autocomplete.option.padding');
        border: 0 none;
        color: dt('autocomplete.option.color');
        background: transparent;
        transition:
            background dt('autocomplete.transition.duration'),
            color dt('autocomplete.transition.duration'),
            border-color dt('autocomplete.transition.duration');
        border-radius: dt('autocomplete.option.border.radius');
    }

    .p-autocomplete-option:not(.p-autocomplete-option-selected):not(.p-disabled).p-focus {
        background: dt('autocomplete.option.focus.background');
        color: dt('autocomplete.option.focus.color');
    }

    .p-autocomplete-option:not(.p-autocomplete-option-selected):not(.p-disabled):hover {
        background: dt('autocomplete.option.focus.background');
        color: dt('autocomplete.option.focus.color');
    }

    .p-autocomplete-option-selected {
        background: dt('autocomplete.option.selected.background');
        color: dt('autocomplete.option.selected.color');
    }

    .p-autocomplete-option-selected.p-focus {
        background: dt('autocomplete.option.selected.focus.background');
        color: dt('autocomplete.option.selected.focus.color');
    }

    .p-autocomplete-option-group {
        margin: 0;
        padding: dt('autocomplete.option.group.padding');
        color: dt('autocomplete.option.group.color');
        background: dt('autocomplete.option.group.background');
        font-weight: dt('autocomplete.option.group.font.weight');
    }

    .p-autocomplete-input-multiple {
        margin: 0;
        list-style-type: none;
        cursor: text;
        overflow: hidden;
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        padding: calc(dt('autocomplete.padding.y') / 2) dt('autocomplete.padding.x');
        gap: calc(dt('autocomplete.padding.y') / 2);
        color: dt('autocomplete.color');
        background: dt('autocomplete.background');
        border: 1px solid dt('autocomplete.border.color');
        border-radius: dt('autocomplete.border.radius');
        width: 100%;
        transition:
            background dt('autocomplete.transition.duration'),
            color dt('autocomplete.transition.duration'),
            border-color dt('autocomplete.transition.duration'),
            outline-color dt('autocomplete.transition.duration'),
            box-shadow dt('autocomplete.transition.duration');
        outline-color: transparent;
        box-shadow: dt('autocomplete.shadow');
    }

    .p-autocomplete-input-multiple.p-disabled {
        opacity: 1;
        background: dt('autocomplete.disabled.background');
        color: dt('autocomplete.disabled.color');
    }

    .p-autocomplete-input-multiple:not(.p-disabled):hover {
        border-color: dt('autocomplete.hover.border.color');
    }

    .p-autocomplete.p-focus .p-autocomplete-input-multiple:not(.p-disabled) {
        border-color: dt('autocomplete.focus.border.color');
        box-shadow: dt('autocomplete.focus.ring.shadow');
        outline: dt('autocomplete.focus.ring.width') dt('autocomplete.focus.ring.style') dt('autocomplete.focus.ring.color');
        outline-offset: dt('autocomplete.focus.ring.offset');
    }

    .p-autocomplete.p-invalid .p-autocomplete-input-multiple {
        border-color: dt('autocomplete.invalid.border.color');
    }

    .p-variant-filled.p-autocomplete-input-multiple {
        background: dt('autocomplete.filled.background');
    }

    .p-autocomplete-input-multiple.p-variant-filled:not(.p-disabled):hover {
        background: dt('autocomplete.filled.hover.background');
    }

    .p-autocomplete.p-focus .p-autocomplete-input-multiple.p-variant-filled:not(.p-disabled) {
        background: dt('autocomplete.filled.focus.background');
    }

    .p-autocomplete-chip.p-chip {
        padding-block-start: calc(dt('autocomplete.padding.y') / 2);
        padding-block-end: calc(dt('autocomplete.padding.y') / 2);
        border-radius: dt('autocomplete.chip.border.radius');
    }

    .p-autocomplete-input-multiple:has(.p-autocomplete-chip) {
        padding-inline-start: calc(dt('autocomplete.padding.y') / 2);
        padding-inline-end: calc(dt('autocomplete.padding.y') / 2);
    }

    .p-autocomplete-chip-item.p-focus .p-autocomplete-chip {
        background: dt('autocomplete.chip.focus.background');
        color: dt('autocomplete.chip.focus.color');
    }

    .p-autocomplete-input-chip {
        flex: 1 1 auto;
        display: inline-flex;
        padding-block-start: calc(dt('autocomplete.padding.y') / 2);
        padding-block-end: calc(dt('autocomplete.padding.y') / 2);
    }

    .p-autocomplete-input-chip input {
        border: 0 none;
        outline: 0 none;
        background: transparent;
        margin: 0;
        padding: 0;
        box-shadow: none;
        border-radius: 0;
        width: 100%;
        font-family: inherit;
        font-feature-settings: inherit;
        font-size: 1rem;
        color: inherit;
    }

    .p-autocomplete-input-chip input::placeholder {
        color: dt('autocomplete.placeholder.color');
    }

    .p-autocomplete.p-invalid .p-autocomplete-input-chip input::placeholder {
        color: dt('autocomplete.invalid.placeholder.color');
    }

    .p-autocomplete-empty-message {
        padding: dt('autocomplete.empty.message.padding');
    }

    .p-autocomplete-fluid {
        display: flex;
    }

    .p-autocomplete-fluid:has(.p-autocomplete-dropdown) .p-autocomplete-input {
        width: 1%;
    }

    .p-autocomplete:has(.p-inputtext-sm) .p-autocomplete-dropdown {
        width: dt('autocomplete.dropdown.sm.width');
    }

    .p-autocomplete:has(.p-inputtext-sm) .p-autocomplete-dropdown .p-icon {
        font-size: dt('form.field.sm.font.size');
        width: dt('form.field.sm.font.size');
        height: dt('form.field.sm.font.size');
    }

    .p-autocomplete:has(.p-inputtext-lg) .p-autocomplete-dropdown {
        width: dt('autocomplete.dropdown.lg.width');
    }

    .p-autocomplete:has(.p-inputtext-lg) .p-autocomplete-dropdown .p-icon {
        font-size: dt('form.field.lg.font.size');
        width: dt('form.field.lg.font.size');
        height: dt('form.field.lg.font.size');
    }

    .p-autocomplete-clear-icon {
        position: absolute;
        top: 50%;
        margin-top: -0.5rem;
        cursor: pointer;
        color: dt('form.field.icon.color');
        inset-inline-end: dt('autocomplete.padding.x');
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-clear-icon {
        inset-inline-end: calc(dt('autocomplete.padding.x') + dt('autocomplete.dropdown.width'));
    }

    .p-autocomplete:has(.p-autocomplete-clear-icon) .p-autocomplete-input {
        padding-inline-end: calc((dt('form.field.padding.x') * 2) + dt('icon.size'));
    }

    .p-inputgroup .p-autocomplete-dropdown {
        border-radius: 0;
    }

    .p-inputgroup > .p-autocomplete:last-child:has(.p-autocomplete-dropdown) > .p-autocomplete-input {
        border-start-end-radius: 0;
        border-end-end-radius: 0;
    }

    .p-inputgroup > .p-autocomplete:last-child .p-autocomplete-dropdown {
        border-start-end-radius: dt('autocomplete.dropdown.border.radius');
        border-end-end-radius: dt('autocomplete.dropdown.border.radius');
    }
`,Fo={root:{position:"relative"}},Ro={root:function(e){var n=e.instance;return["p-autocomplete p-component p-inputwrapper",{"p-invalid":n.$invalid,"p-focus":n.focused,"p-inputwrapper-filled":n.$filled||fe(n.inputValue),"p-inputwrapper-focus":n.focused,"p-autocomplete-open":n.overlayVisible,"p-autocomplete-fluid":n.$fluid,"p-autocomplete-clearable":n.isClearIconVisible}]},pcInputText:"p-autocomplete-input",inputMultiple:function(e){var n=e.instance,i=e.props;return["p-autocomplete-input-multiple",{"p-variant-filled":n.$variant==="filled","p-disabled":i.disabled}]},clearIcon:"p-autocomplete-clear-icon",chipItem:function(e){var n=e.instance,i=e.i;return["p-autocomplete-chip-item",{"p-focus":n.focusedMultipleOptionIndex===i}]},pcChip:"p-autocomplete-chip",chipIcon:"p-autocomplete-chip-icon",inputChip:"p-autocomplete-input-chip",loader:"p-autocomplete-loader",dropdown:"p-autocomplete-dropdown",overlay:"p-autocomplete-overlay p-component",listContainer:"p-autocomplete-list-container",list:"p-autocomplete-list",optionGroup:"p-autocomplete-option-group",option:function(e){var n=e.instance,i=e.option,s=e.i,o=e.getItemOptions;return["p-autocomplete-option",{"p-autocomplete-option-selected":n.isSelected(i),"p-focus":n.focusedOptionIndex===n.getOptionIndex(s,o),"p-disabled":n.isOptionDisabled(i)}]},emptyMessage:"p-autocomplete-empty-message"},jo=he.extend({name:"autocomplete",style:Bo,classes:Ro,inlineStyles:Fo}),Ko={name:"BaseAutoComplete",extends:yn,props:{suggestions:{type:Array,default:null},optionLabel:null,optionDisabled:null,optionGroupLabel:null,optionGroupChildren:null,scrollHeight:{type:String,default:"14rem"},dropdown:{type:Boolean,default:!1},dropdownMode:{type:String,default:"blank"},multiple:{type:Boolean,default:!1},loading:{type:Boolean,default:!1},placeholder:{type:String,default:null},dataKey:{type:String,default:null},minLength:{type:Number,default:1},delay:{type:Number,default:300},appendTo:{type:[String,Object],default:"body"},forceSelection:{type:Boolean,default:!1},completeOnFocus:{type:Boolean,default:!1},showClear:{type:Boolean,default:!1},inputId:{type:String,default:null},inputStyle:{type:Object,default:null},inputClass:{type:[String,Object],default:null},panelStyle:{type:Object,default:null},panelClass:{type:[String,Object],default:null},overlayStyle:{type:Object,default:null},overlayClass:{type:[String,Object],default:null},dropdownIcon:{type:String,default:null},dropdownClass:{type:[String,Object],default:null},loader:{type:String,default:null},loadingIcon:{type:String,default:null},removeTokenIcon:{type:String,default:null},chipIcon:{type:String,default:null},virtualScrollerOptions:{type:Object,default:null},autoOptionFocus:{type:Boolean,default:!1},selectOnFocus:{type:Boolean,default:!1},focusOnHover:{type:Boolean,default:!0},searchLocale:{type:String,default:void 0},searchMessage:{type:String,default:null},selectionMessage:{type:String,default:null},emptySelectionMessage:{type:String,default:null},emptySearchMessage:{type:String,default:null},showEmptyMessage:{type:Boolean,default:!0},tabindex:{type:Number,default:0},typeahead:{type:Boolean,default:!0},ariaLabel:{type:String,default:null},ariaLabelledby:{type:String,default:null}},style:jo,provide:function(){return{$pcAutoComplete:this,$parentInstance:this}}};function Zt(t,e,n){return(e=Ho(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Ho(t){var e=No(t,"string");return ke(e)=="symbol"?e:e+""}function No(t,e){if(ke(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(ke(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}function ke(t){"@babel/helpers - typeof";return ke=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},ke(t)}function Je(t){return Zo(t)||Wo(t)||Go(t)||Uo()}function Uo(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Go(t,e){if(t){if(typeof t=="string")return mt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?mt(t,e):void 0}}function Wo(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function Zo(t){if(Array.isArray(t))return mt(t)}function mt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}var Cn={name:"AutoComplete",extends:Ko,inheritAttrs:!1,emits:["change","focus","blur","item-select","item-unselect","option-select","option-unselect","dropdown-click","clear","complete","before-show","before-hide","show","hide"],inject:{$pcFluid:{default:null}},outsideClickListener:null,resizeListener:null,scrollHandler:null,overlay:null,virtualScroller:null,searchTimeout:null,dirty:!1,startRangeIndex:-1,data:function(){return{clicked:!1,focused:!1,focusedOptionIndex:-1,focusedMultipleOptionIndex:-1,overlayVisible:!1,searching:!1}},watch:{suggestions:function(){this.searching&&(this.show(),this.focusedOptionIndex=this.overlayVisible&&this.autoOptionFocus?this.findFirstFocusedOptionIndex():-1,this.searching=!1,!this.showEmptyMessage&&this.visibleOptions.length===0&&this.hide()),this.autoUpdateModel()}},mounted:function(){this.autoUpdateModel()},updated:function(){this.overlayVisible&&this.alignOverlay()},beforeUnmount:function(){this.unbindOutsideClickListener(),this.unbindResizeListener(),this.scrollHandler&&(this.scrollHandler.destroy(),this.scrollHandler=null),this.overlay&&(Oe.clear(this.overlay),this.overlay=null)},methods:{getOptionIndex:function(e,n){return this.virtualScrollerDisabled?e:n&&n(e).index},getOptionLabel:function(e){return this.optionLabel?_e(e,this.optionLabel):e},getOptionValue:function(e){return e},getOptionRenderKey:function(e,n){return(this.dataKey?_e(e,this.dataKey):this.getOptionLabel(e))+"_"+n},getPTOptions:function(e,n,i,s){return this.ptm(s,{context:{option:e,index:i,selected:this.isSelected(e),focused:this.focusedOptionIndex===this.getOptionIndex(i,n),disabled:this.isOptionDisabled(e)}})},isOptionDisabled:function(e){return this.optionDisabled?_e(e,this.optionDisabled):!1},isOptionGroup:function(e){return this.optionGroupLabel&&e.optionGroup&&e.group},getOptionGroupLabel:function(e){return _e(e,this.optionGroupLabel)},getOptionGroupChildren:function(e){return _e(e,this.optionGroupChildren)},getAriaPosInset:function(e){var n=this;return(this.optionGroupLabel?e-this.visibleOptions.slice(0,e).filter(function(i){return n.isOptionGroup(i)}).length:e)+1},show:function(e){this.$emit("before-show"),this.dirty=!0,this.overlayVisible=!0,this.focusedOptionIndex=this.focusedOptionIndex!==-1?this.focusedOptionIndex:this.autoOptionFocus?this.findFirstFocusedOptionIndex():-1,e&&ie(this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el)},hide:function(e){var n=this,i=function(){var o;n.$emit("before-hide"),n.dirty=e,n.overlayVisible=!1,n.clicked=!1,n.focusedOptionIndex=-1,e&&ie(n.multiple?n.$refs.focusInput:(o=n.$refs.focusInput)===null||o===void 0?void 0:o.$el)};setTimeout(function(){i()},0)},onFocus:function(e){this.disabled||(!this.dirty&&this.completeOnFocus&&this.search(e,e.target.value,"focus"),this.dirty=!0,this.focused=!0,this.overlayVisible&&(this.focusedOptionIndex=this.focusedOptionIndex!==-1?this.focusedOptionIndex:this.overlayVisible&&this.autoOptionFocus?this.findFirstFocusedOptionIndex():-1,this.scrollInView(this.focusedOptionIndex)),this.$emit("focus",e))},onBlur:function(e){var n,i;this.dirty=!1,this.focused=!1,this.focusedOptionIndex=-1,this.$emit("blur",e),(n=(i=this.formField).onBlur)===null||n===void 0||n.call(i)},onKeyDown:function(e){if(this.disabled){e.preventDefault();return}switch(e.code){case"ArrowDown":this.onArrowDownKey(e);break;case"ArrowUp":this.onArrowUpKey(e);break;case"ArrowLeft":this.onArrowLeftKey(e);break;case"ArrowRight":this.onArrowRightKey(e);break;case"Home":this.onHomeKey(e);break;case"End":this.onEndKey(e);break;case"PageDown":this.onPageDownKey(e);break;case"PageUp":this.onPageUpKey(e);break;case"Enter":case"NumpadEnter":this.onEnterKey(e);break;case"Space":this.onSpaceKey(e);break;case"Escape":this.onEscapeKey(e);break;case"Tab":this.onTabKey(e);break;case"ShiftLeft":case"ShiftRight":this.onShiftKey(e);break;case"Backspace":this.onBackspaceKey(e);break}this.clicked=!1},onInput:function(e){var n=this;if(this.typeahead){this.searchTimeout&&clearTimeout(this.searchTimeout);var i=e.target.value;this.multiple||this.updateModel(e,i),i.length===0?(this.searching=!1,this.hide(),this.$emit("clear")):i.length>=this.minLength?(this.focusedOptionIndex=-1,this.searchTimeout=setTimeout(function(){n.search(e,i,"input")},this.delay)):(this.searching=!1,this.hide())}},onChange:function(e){var n=this;if(this.forceSelection){var i=!1;if(this.visibleOptions&&!this.multiple){var s,o=this.multiple?this.$refs.focusInput.value:(s=this.$refs.focusInput)===null||s===void 0||(s=s.$el)===null||s===void 0?void 0:s.value,c=this.visibleOptions.find(function(g){return n.isOptionMatched(g,o||"")});c!==void 0&&(i=!0,!this.isSelected(c)&&this.onOptionSelect(e,c))}if(!i){if(this.multiple)this.$refs.focusInput.value="";else{var p,m=(p=this.$refs.focusInput)===null||p===void 0?void 0:p.$el;m&&(m.value="")}this.$emit("clear"),!this.multiple&&this.updateModel(e,null)}}},onMultipleContainerFocus:function(){this.disabled||(this.focused=!0)},onMultipleContainerBlur:function(){this.focusedMultipleOptionIndex=-1,this.focused=!1},onMultipleContainerKeyDown:function(e){if(this.disabled){e.preventDefault();return}switch(e.code){case"ArrowLeft":this.onArrowLeftKeyOnMultiple(e);break;case"ArrowRight":this.onArrowRightKeyOnMultiple(e);break;case"Backspace":this.onBackspaceKeyOnMultiple(e);break}},onContainerClick:function(e){this.clicked=!0,!(this.disabled||this.searching||this.loading||this.isDropdownClicked(e))&&(!this.overlay||!this.overlay.contains(e.target))&&ie(this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el)},onDropdownClick:function(e){var n=void 0;if(this.overlayVisible)this.hide(!0);else{var i=this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el;ie(i),n=i.value,this.dropdownMode==="blank"?this.search(e,"","dropdown"):this.dropdownMode==="current"&&this.search(e,n,"dropdown")}this.$emit("dropdown-click",{originalEvent:e,query:n})},onOptionSelect:function(e,n){var i=arguments.length>2&&arguments[2]!==void 0?arguments[2]:!0,s=this.getOptionValue(n);this.multiple?(this.$refs.focusInput.value="",this.isSelected(n)||this.updateModel(e,[].concat(Je(this.d_value||[]),[s]))):this.updateModel(e,s),this.$emit("item-select",{originalEvent:e,value:n}),this.$emit("option-select",{originalEvent:e,value:n}),i&&this.hide(!0)},onOptionMouseMove:function(e,n){this.focusOnHover&&this.changeFocusedOptionIndex(e,n)},onOptionSelectRange:function(e){var n=this,i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:-1,s=arguments.length>2&&arguments[2]!==void 0?arguments[2]:-1;if(i===-1&&(i=this.findNearestSelectedOptionIndex(s,!0)),s===-1&&(s=this.findNearestSelectedOptionIndex(i)),i!==-1&&s!==-1){var o=Math.min(i,s),c=Math.max(i,s),p=this.visibleOptions.slice(o,c+1).filter(function(m){return n.isValidOption(m)}).filter(function(m){return!n.isSelected(m)}).map(function(m){return n.getOptionValue(m)});this.updateModel(e,[].concat(Je(this.d_value||[]),Je(p)))}},onClearClick:function(e){this.updateModel(e,null),this.$emit("clear")},onOverlayClick:function(e){Po.emit("overlay-click",{originalEvent:e,target:this.$el})},onOverlayKeyDown:function(e){switch(e.code){case"Escape":this.onEscapeKey(e);break}},onArrowDownKey:function(e){if(this.overlayVisible){var n=this.focusedOptionIndex!==-1?this.findNextOptionIndex(this.focusedOptionIndex):this.clicked?this.findFirstOptionIndex():this.findFirstFocusedOptionIndex();this.multiple&&e.shiftKey&&this.onOptionSelectRange(e,this.startRangeIndex,n),this.changeFocusedOptionIndex(e,n),e.preventDefault()}},onArrowUpKey:function(e){if(this.overlayVisible)if(e.altKey)this.focusedOptionIndex!==-1&&this.onOptionSelect(e,this.visibleOptions[this.focusedOptionIndex]),this.overlayVisible&&this.hide(),e.preventDefault();else{var n=this.focusedOptionIndex!==-1?this.findPrevOptionIndex(this.focusedOptionIndex):this.clicked?this.findLastOptionIndex():this.findLastFocusedOptionIndex();this.multiple&&e.shiftKey&&this.onOptionSelectRange(e,n,this.startRangeIndex),this.changeFocusedOptionIndex(e,n),e.preventDefault()}},onArrowLeftKey:function(e){var n=e.currentTarget;this.focusedOptionIndex=-1,this.multiple&&(ti(n.value)&&this.$filled?(ie(this.$refs.multiContainer),this.focusedMultipleOptionIndex=this.d_value.length):e.stopPropagation())},onArrowRightKey:function(e){this.focusedOptionIndex=-1,this.multiple&&e.stopPropagation()},onHomeKey:function(e){var n=e.currentTarget,i=n.value.length,s=e.metaKey||e.ctrlKey,o=this.findFirstOptionIndex();this.multiple&&e.shiftKey&&s&&this.onOptionSelectRange(e,o,this.startRangeIndex),n.setSelectionRange(0,e.shiftKey?i:0),this.focusedOptionIndex=-1,e.preventDefault()},onEndKey:function(e){var n=e.currentTarget,i=n.value.length,s=e.metaKey||e.ctrlKey,o=this.findLastOptionIndex();this.multiple&&e.shiftKey&&s&&this.onOptionSelectRange(e,this.startRangeIndex,o),n.setSelectionRange(e.shiftKey?0:i,i),this.focusedOptionIndex=-1,e.preventDefault()},onPageUpKey:function(e){this.scrollInView(0),e.preventDefault()},onPageDownKey:function(e){this.scrollInView(this.visibleOptions.length-1),e.preventDefault()},onEnterKey:function(e){this.typeahead?this.overlayVisible?(this.focusedOptionIndex!==-1&&(this.multiple&&e.shiftKey?this.onOptionSelectRange(e,this.focusedOptionIndex):this.onOptionSelect(e,this.visibleOptions[this.focusedOptionIndex]),e.preventDefault()),this.hide()):(this.focusedOptionIndex=-1,this.onArrowDownKey(e)):this.multiple&&(e.target.value.trim()&&(this.updateModel(e,[].concat(Je(this.d_value||[]),[e.target.value.trim()])),this.$refs.focusInput.value=""),e.preventDefault())},onSpaceKey:function(e){!this.autoOptionFocus&&this.focusedOptionIndex!==-1&&this.onEnterKey(e)},onEscapeKey:function(e){this.overlayVisible&&this.hide(!0),e.preventDefault()},onTabKey:function(e){this.focusedOptionIndex!==-1&&this.onOptionSelect(e,this.visibleOptions[this.focusedOptionIndex]),this.overlayVisible&&this.hide()},onShiftKey:function(){this.startRangeIndex=this.focusedOptionIndex},onBackspaceKey:function(e){if(this.multiple){if(fe(this.d_value)&&!this.$refs.focusInput.value){var n=this.d_value[this.d_value.length-1],i=this.d_value.slice(0,-1);this.writeValue(i,e),this.$emit("item-unselect",{originalEvent:e,value:n}),this.$emit("option-unselect",{originalEvent:e,value:n})}e.stopPropagation()}},onArrowLeftKeyOnMultiple:function(){this.focusedMultipleOptionIndex=this.focusedMultipleOptionIndex<1?0:this.focusedMultipleOptionIndex-1},onArrowRightKeyOnMultiple:function(){this.focusedMultipleOptionIndex++,this.focusedMultipleOptionIndex>this.d_value.length-1&&(this.focusedMultipleOptionIndex=-1,ie(this.$refs.focusInput))},onBackspaceKeyOnMultiple:function(e){this.focusedMultipleOptionIndex!==-1&&this.removeOption(e,this.focusedMultipleOptionIndex)},onOverlayEnter:function(e){Oe.set("overlay",e,this.$primevue.config.zIndex.overlay),rn(e,{position:"absolute",top:"0"}),this.alignOverlay(),this.$attrSelector&&e.setAttribute(this.$attrSelector,"")},onOverlayAfterEnter:function(){this.bindOutsideClickListener(),this.bindScrollListener(),this.bindResizeListener(),this.$emit("show")},onOverlayLeave:function(e){e.style.pointerEvents="none",this.unbindOutsideClickListener(),this.unbindScrollListener(),this.unbindResizeListener(),this.$emit("hide"),this.overlay=null},onOverlayAfterLeave:function(e){Oe.clear(e)},alignOverlay:function(){var e=this.multiple?this.$refs.multiContainer:this.$refs.focusInput.$el;this.appendTo==="self"?qn(this.overlay,e):(this.overlay.style.minWidth=an(e)+"px",ei(this.overlay,e))},bindOutsideClickListener:function(){var e=this;this.outsideClickListener||(this.outsideClickListener=function(n){e.overlayVisible&&e.overlay&&e.isOutsideClicked(n)&&e.hide()},document.addEventListener("click",this.outsideClickListener,!0))},unbindOutsideClickListener:function(){this.outsideClickListener&&(document.removeEventListener("click",this.outsideClickListener,!0),this.outsideClickListener=null)},bindScrollListener:function(){var e=this;this.scrollHandler||(this.scrollHandler=new qi(this.$refs.container,function(){e.overlayVisible&&e.hide()})),this.scrollHandler.bindScrollListener()},unbindScrollListener:function(){this.scrollHandler&&this.scrollHandler.unbindScrollListener()},bindResizeListener:function(){var e=this;this.resizeListener||(this.resizeListener=function(){e.overlayVisible&&!Qn()&&e.hide()},window.addEventListener("resize",this.resizeListener))},unbindResizeListener:function(){this.resizeListener&&(window.removeEventListener("resize",this.resizeListener),this.resizeListener=null)},isOutsideClicked:function(e){return!this.overlay.contains(e.target)&&!this.isInputClicked(e)&&!this.isDropdownClicked(e)},isInputClicked:function(e){return this.multiple?e.target===this.$refs.multiContainer||this.$refs.multiContainer.contains(e.target):e.target===this.$refs.focusInput.$el},isDropdownClicked:function(e){return this.$refs.dropdownButton?e.target===this.$refs.dropdownButton||this.$refs.dropdownButton.contains(e.target):!1},isOptionMatched:function(e,n){var i;return this.isValidOption(e)&&((i=this.getOptionLabel(e))===null||i===void 0?void 0:i.toLocaleLowerCase(this.searchLocale))===n.toLocaleLowerCase(this.searchLocale)},isValidOption:function(e){return fe(e)&&!(this.isOptionDisabled(e)||this.isOptionGroup(e))},isValidSelectedOption:function(e){return this.isValidOption(e)&&this.isSelected(e)},isEquals:function(e,n){return Jn(e,n,this.equalityKey)},isSelected:function(e){var n=this,i=this.getOptionValue(e);return this.multiple?(this.d_value||[]).some(function(s){return n.isEquals(s,i)}):this.isEquals(this.d_value,this.getOptionValue(e))},findFirstOptionIndex:function(){var e=this;return this.visibleOptions.findIndex(function(n){return e.isValidOption(n)})},findLastOptionIndex:function(){var e=this;return lt(this.visibleOptions,function(n){return e.isValidOption(n)})},findNextOptionIndex:function(e){var n=this,i=e<this.visibleOptions.length-1?this.visibleOptions.slice(e+1).findIndex(function(s){return n.isValidOption(s)}):-1;return i>-1?i+e+1:e},findPrevOptionIndex:function(e){var n=this,i=e>0?lt(this.visibleOptions.slice(0,e),function(s){return n.isValidOption(s)}):-1;return i>-1?i:e},findSelectedOptionIndex:function(){var e=this;return this.$filled?this.visibleOptions.findIndex(function(n){return e.isValidSelectedOption(n)}):-1},findFirstFocusedOptionIndex:function(){var e=this.findSelectedOptionIndex();return e<0?this.findFirstOptionIndex():e},findLastFocusedOptionIndex:function(){var e=this.findSelectedOptionIndex();return e<0?this.findLastOptionIndex():e},search:function(e,n,i){n!=null&&(i==="input"&&n.trim().length===0||(this.searching=!0,this.$emit("complete",{originalEvent:e,query:n})))},removeOption:function(e,n){var i=this,s=this.d_value[n],o=this.d_value.filter(function(c,p){return p!==n}).map(function(c){return i.getOptionValue(c)});this.updateModel(e,o),this.$emit("item-unselect",{originalEvent:e,value:s}),this.$emit("option-unselect",{originalEvent:e,value:s}),this.dirty=!0,ie(this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el)},changeFocusedOptionIndex:function(e,n){this.focusedOptionIndex!==n&&(this.focusedOptionIndex=n,this.scrollInView(),this.selectOnFocus&&this.onOptionSelect(e,this.visibleOptions[n],!1))},scrollInView:function(){var e=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:-1;this.$nextTick(function(){var i=n!==-1?"".concat(e.$id,"_").concat(n):e.focusedOptionId,s=un(e.list,'li[id="'.concat(i,'"]'));s?s.scrollIntoView&&s.scrollIntoView({block:"nearest",inline:"start"}):e.virtualScrollerDisabled||e.virtualScroller&&e.virtualScroller.scrollToIndex(n!==-1?n:e.focusedOptionIndex)})},autoUpdateModel:function(){this.selectOnFocus&&this.autoOptionFocus&&!this.$filled&&(this.focusedOptionIndex=this.findFirstFocusedOptionIndex(),this.onOptionSelect(null,this.visibleOptions[this.focusedOptionIndex],!1))},updateModel:function(e,n){this.writeValue(n,e),this.$emit("change",{originalEvent:e,value:n})},flatOptions:function(e){var n=this;return(e||[]).reduce(function(i,s,o){i.push({optionGroup:s,group:!0,index:o});var c=n.getOptionGroupChildren(s);return c&&c.forEach(function(p){return i.push(p)}),i},[])},overlayRef:function(e){this.overlay=e},listRef:function(e,n){this.list=e,n&&n(e)},virtualScrollerRef:function(e){this.virtualScroller=e},findNextSelectedOptionIndex:function(e){var n=this,i=this.$filled&&e<this.visibleOptions.length-1?this.visibleOptions.slice(e+1).findIndex(function(s){return n.isValidSelectedOption(s)}):-1;return i>-1?i+e+1:-1},findPrevSelectedOptionIndex:function(e){var n=this,i=this.$filled&&e>0?lt(this.visibleOptions.slice(0,e),function(s){return n.isValidSelectedOption(s)}):-1;return i>-1?i:-1},findNearestSelectedOptionIndex:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,i=-1;return this.$filled&&(n?(i=this.findPrevSelectedOptionIndex(e),i=i===-1?this.findNextSelectedOptionIndex(e):i):(i=this.findNextSelectedOptionIndex(e),i=i===-1?this.findPrevSelectedOptionIndex(e):i)),i>-1?i:e}},computed:{visibleOptions:function(){return this.optionGroupLabel?this.flatOptions(this.suggestions):this.suggestions||[]},inputValue:function(){if(this.$filled)if(ke(this.d_value)==="object"){var e=this.getOptionLabel(this.d_value);return e??this.d_value}else return this.d_value;else return""},hasSelectedOption:function(){return this.$filled},equalityKey:function(){return this.dataKey},searchResultMessageText:function(){return fe(this.visibleOptions)&&this.overlayVisible?this.searchMessageText.replaceAll("{0}",this.visibleOptions.length):this.emptySearchMessageText},searchMessageText:function(){return this.searchMessage||this.$primevue.config.locale.searchMessage||""},emptySearchMessageText:function(){return this.emptySearchMessage||this.$primevue.config.locale.emptySearchMessage||""},selectionMessageText:function(){return this.selectionMessage||this.$primevue.config.locale.selectionMessage||""},emptySelectionMessageText:function(){return this.emptySelectionMessage||this.$primevue.config.locale.emptySelectionMessage||""},selectedMessageText:function(){return this.$filled?this.selectionMessageText.replaceAll("{0}",this.multiple?this.d_value.length:"1"):this.emptySelectionMessageText},listAriaLabel:function(){return this.$primevue.config.locale.aria?this.$primevue.config.locale.aria.listLabel:void 0},focusedOptionId:function(){return this.focusedOptionIndex!==-1?"".concat(this.$id,"_").concat(this.focusedOptionIndex):null},focusedMultipleOptionId:function(){return this.focusedMultipleOptionIndex!==-1?"".concat(this.$id,"_multiple_option_").concat(this.focusedMultipleOptionIndex):null},isClearIconVisible:function(){return this.showClear&&this.$filled&&!this.disabled&&!this.loading},ariaSetSize:function(){var e=this;return this.visibleOptions.filter(function(n){return!e.isOptionGroup(n)}).length},virtualScrollerDisabled:function(){return!this.virtualScrollerOptions},panelId:function(){return this.$id+"_panel"},containerDataP:function(){return me({fluid:this.$fluid})},overlayDataP:function(){return me(Zt({},"portal-"+this.appendTo,"portal-"+this.appendTo))},inputMultipleDataP:function(){return me(Zt({invalid:this.$invalid,disabled:this.disabled,focus:this.focused,fluid:this.$fluid,filled:this.$variant==="filled",empty:!this.$filled},this.size,this.size))}},components:{InputText:bt,VirtualScroller:wn,Portal:yt,Chip:vn,ChevronDownIcon:hn,SpinnerIcon:ln,TimesIcon:et},directives:{ripple:vt}};function Fe(t){"@babel/helpers - typeof";return Fe=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Fe(t)}function Yt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function Xt(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Yt(Object(n),!0).forEach(function(i){Yo(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Yt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function Yo(t,e,n){return(e=Xo(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Xo(t){var e=Jo(t,"string");return Fe(e)=="symbol"?e:e+""}function Jo(t,e){if(Fe(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Fe(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Qo=["data-p"],qo=["aria-activedescendant","data-p-has-dropdown","data-p"],es=["id","aria-label","aria-setsize","aria-posinset"],ts=["id","placeholder","tabindex","disabled","aria-label","aria-labelledby","aria-expanded","aria-controls","aria-activedescendant","aria-invalid"],ns=["data-p-has-dropdown"],is=["disabled","aria-expanded","aria-controls"],os=["id","data-p"],ss=["id","aria-label"],as=["id"],rs=["id","aria-label","aria-selected","aria-disabled","aria-setsize","aria-posinset","onClick","onMousemove","data-p-selected","data-p-focused","data-p-disabled"];function ls(t,e,n,i,s,o){var c=ae("InputText"),p=ae("TimesIcon"),m=ae("Chip"),g=ae("SpinnerIcon"),h=ae("VirtualScroller"),v=ae("Portal"),S=ht("ripple");return u(),d("div",w({ref:"container",class:t.cx("root"),style:t.sx("root"),onClick:e[11]||(e[11]=function(){return o.onContainerClick&&o.onContainerClick.apply(o,arguments)}),"data-p":o.containerDataP},t.ptmi("root")),[t.multiple?b("",!0):(u(),G(c,{key:0,ref:"focusInput",id:t.inputId,type:"text",name:t.$formName,class:ee([t.cx("pcInputText"),t.inputClass]),style:Mn(t.inputStyle),defaultValue:o.inputValue,placeholder:t.placeholder,tabindex:t.disabled?-1:t.tabindex,fluid:t.$fluid,disabled:t.disabled,size:t.size,invalid:t.invalid,variant:t.variant,autocomplete:"off",role:"combobox","aria-label":t.ariaLabel,"aria-labelledby":t.ariaLabelledby,"aria-haspopup":"listbox","aria-autocomplete":"list","aria-expanded":s.overlayVisible,"aria-controls":s.overlayVisible?o.panelId:void 0,"aria-activedescendant":s.focused?o.focusedOptionId:void 0,onFocus:o.onFocus,onBlur:o.onBlur,onKeydown:o.onKeyDown,onInput:o.onInput,onChange:o.onChange,unstyled:t.unstyled,"data-p-has-dropdown":t.dropdown,pt:t.ptm("pcInputText")},null,8,["id","name","class","style","defaultValue","placeholder","tabindex","fluid","disabled","size","invalid","variant","aria-label","aria-labelledby","aria-expanded","aria-controls","aria-activedescendant","onFocus","onBlur","onKeydown","onInput","onChange","unstyled","data-p-has-dropdown","pt"])),o.isClearIconVisible?P(t.$slots,"clearicon",{key:1,class:ee(t.cx("clearIcon")),clearCallback:o.onClearClick},function(){return[H(p,w({class:[t.cx("clearIcon")],onClick:o.onClearClick},t.ptm("clearIcon")),null,16,["class","onClick"])]}):b("",!0),t.multiple?(u(),d("ul",w({key:2,ref:"multiContainer",class:t.cx("inputMultiple"),tabindex:"-1",role:"listbox","aria-orientation":"horizontal","aria-activedescendant":s.focused?o.focusedMultipleOptionId:void 0,onFocus:e[5]||(e[5]=function(){return o.onMultipleContainerFocus&&o.onMultipleContainerFocus.apply(o,arguments)}),onBlur:e[6]||(e[6]=function(){return o.onMultipleContainerBlur&&o.onMultipleContainerBlur.apply(o,arguments)}),onKeydown:e[7]||(e[7]=function(){return o.onMultipleContainerKeyDown&&o.onMultipleContainerKeyDown.apply(o,arguments)}),"data-p-has-dropdown":t.dropdown,"data-p":o.inputMultipleDataP},t.ptm("inputMultiple")),[(u(!0),d(q,null,re(t.d_value,function(C,k){return u(),d("li",w({key:"".concat(k,"_").concat(o.getOptionLabel(C)),id:t.$id+"_multiple_option_"+k,class:t.cx("chipItem",{i:k}),role:"option","aria-label":o.getOptionLabel(C),"aria-selected":!0,"aria-setsize":t.d_value.length,"aria-posinset":k+1},{ref_for:!0},t.ptm("chipItem")),[P(t.$slots,"chip",w({class:t.cx("pcChip"),value:C,index:k,removeCallback:function(_){return o.removeOption(_,k)}},{ref_for:!0},t.ptm("pcChip")),function(){return[H(m,{class:ee(t.cx("pcChip")),label:o.getOptionLabel(C),removeIcon:t.chipIcon||t.removeTokenIcon,removable:"",unstyled:t.unstyled,onRemove:function(_){return o.removeOption(_,k)},"data-p-focused":s.focusedMultipleOptionIndex===k,pt:t.ptm("pcChip")},{removeicon:ne(function(){return[P(t.$slots,t.$slots.chipicon?"chipicon":"removetokenicon",{class:ee(t.cx("chipIcon")),index:k,removeCallback:function(_){return o.removeOption(_,k)}})]}),_:2},1032,["class","label","removeIcon","unstyled","onRemove","data-p-focused","pt"])]})],16,es)}),128)),f("li",w({class:t.cx("inputChip"),role:"option"},t.ptm("inputChip")),[f("input",w({ref:"focusInput",id:t.inputId,type:"text",style:t.inputStyle,class:t.inputClass,placeholder:t.placeholder,tabindex:t.disabled?-1:t.tabindex,disabled:t.disabled,autocomplete:"off",role:"combobox","aria-label":t.ariaLabel,"aria-labelledby":t.ariaLabelledby,"aria-haspopup":"listbox","aria-autocomplete":"list","aria-expanded":s.overlayVisible,"aria-controls":t.$id+"_list","aria-activedescendant":s.focused?o.focusedOptionId:void 0,"aria-invalid":t.invalid||void 0,onFocus:e[0]||(e[0]=function(){return o.onFocus&&o.onFocus.apply(o,arguments)}),onBlur:e[1]||(e[1]=function(){return o.onBlur&&o.onBlur.apply(o,arguments)}),onKeydown:e[2]||(e[2]=function(){return o.onKeyDown&&o.onKeyDown.apply(o,arguments)}),onInput:e[3]||(e[3]=function(){return o.onInput&&o.onInput.apply(o,arguments)}),onChange:e[4]||(e[4]=function(){return o.onChange&&o.onChange.apply(o,arguments)})},t.ptm("input")),null,16,ts)],16)],16,qo)):b("",!0),s.searching||t.loading?P(t.$slots,t.$slots.loader?"loader":"loadingicon",{key:3,class:ee(t.cx("loader"))},function(){return[t.loader||t.loadingIcon?(u(),d("i",w({key:0,class:["pi-spin",t.cx("loader"),t.loader,t.loadingIcon],"aria-hidden":"true","data-p-has-dropdown":t.dropdown},t.ptm("loader")),null,16,ns)):t.loading?(u(),G(g,w({key:1,class:t.cx("loader"),spin:"","aria-hidden":"true","data-p-has-dropdown":t.dropdown},t.ptm("loader")),null,16,["class","data-p-has-dropdown"])):b("",!0)]}):b("",!0),P(t.$slots,t.$slots.dropdown?"dropdown":"dropdownbutton",{toggleCallback:function(k){return o.onDropdownClick(k)}},function(){return[t.dropdown?(u(),d("button",w({key:0,ref:"dropdownButton",type:"button",class:[t.cx("dropdown"),t.dropdownClass],disabled:t.disabled,"aria-haspopup":"listbox","aria-expanded":s.overlayVisible,"aria-controls":o.panelId,onClick:e[8]||(e[8]=function(){return o.onDropdownClick&&o.onDropdownClick.apply(o,arguments)})},t.ptm("dropdown")),[P(t.$slots,"dropdownicon",{class:ee(t.dropdownIcon)},function(){return[(u(),G(Ie(t.dropdownIcon?"span":"ChevronDownIcon"),w({class:t.dropdownIcon},t.ptm("dropdownIcon")),null,16,["class"]))]})],16,is)):b("",!0)]}),t.typeahead?(u(),d("span",w({key:4,role:"status","aria-live":"polite",class:"p-hidden-accessible"},t.ptm("hiddenSearchResult"),{"data-p-hidden-accessible":!0}),y(o.searchResultMessageText),17)):b("",!0),H(v,{appendTo:t.appendTo},{default:ne(function(){return[H(gt,w({name:"p-anchored-overlay",onEnter:o.onOverlayEnter,onAfterEnter:o.onOverlayAfterEnter,onLeave:o.onOverlayLeave,onAfterLeave:o.onOverlayAfterLeave},t.ptm("transition")),{default:ne(function(){return[s.overlayVisible?(u(),d("div",w({key:0,ref:o.overlayRef,id:o.panelId,class:[t.cx("overlay"),t.panelClass,t.overlayClass],style:Xt(Xt({},t.panelStyle),t.overlayStyle),onClick:e[9]||(e[9]=function(){return o.onOverlayClick&&o.onOverlayClick.apply(o,arguments)}),onKeydown:e[10]||(e[10]=function(){return o.onOverlayKeyDown&&o.onOverlayKeyDown.apply(o,arguments)}),"data-p":o.overlayDataP},t.ptm("overlay")),[P(t.$slots,"header",{value:t.d_value,suggestions:o.visibleOptions}),f("div",w({class:t.cx("listContainer"),style:{"max-height":o.virtualScrollerDisabled?t.scrollHeight:""}},t.ptm("listContainer")),[H(h,w({ref:o.virtualScrollerRef},t.virtualScrollerOptions,{style:{height:t.scrollHeight},items:o.visibleOptions,tabindex:-1,disabled:o.virtualScrollerDisabled,pt:t.ptm("virtualScroller")}),An({content:ne(function(C){var k=C.styleClass,L=C.contentRef,_=C.items,M=C.getItemOptions,A=C.contentStyle,R=C.itemSize;return[f("ul",w({ref:function(B){return o.listRef(B,L)},id:t.$id+"_list",class:[t.cx("list"),k],style:A,role:"listbox","aria-label":o.listAriaLabel},t.ptm("list")),[(u(!0),d(q,null,re(_,function(x,B){return u(),d(q,{key:o.getOptionRenderKey(x,o.getOptionIndex(B,M))},[o.isOptionGroup(x)?(u(),d("li",w({key:0,id:t.$id+"_"+o.getOptionIndex(B,M),style:{height:R?R+"px":void 0},class:t.cx("optionGroup"),role:"option"},{ref_for:!0},t.ptm("optionGroup")),[P(t.$slots,"optiongroup",{option:x.optionGroup,index:o.getOptionIndex(B,M)},function(){return[F(y(o.getOptionGroupLabel(x.optionGroup)),1)]})],16,as)):Se((u(),d("li",w({key:1,id:t.$id+"_"+o.getOptionIndex(B,M),style:{height:R?R+"px":void 0},class:t.cx("option",{option:x,i:B,getItemOptions:M}),role:"option","aria-label":o.getOptionLabel(x),"aria-selected":o.isSelected(x),"aria-disabled":o.isOptionDisabled(x),"aria-setsize":o.ariaSetSize,"aria-posinset":o.getAriaPosInset(o.getOptionIndex(B,M)),onClick:function(O){return o.onOptionSelect(O,x)},onMousemove:function(O){return o.onOptionMouseMove(O,o.getOptionIndex(B,M))},"data-p-selected":o.isSelected(x),"data-p-focused":s.focusedOptionIndex===o.getOptionIndex(B,M),"data-p-disabled":o.isOptionDisabled(x)},{ref_for:!0},o.getPTOptions(x,M,B,"option")),[P(t.$slots,"option",{option:x,index:o.getOptionIndex(B,M)},function(){return[F(y(o.getOptionLabel(x)),1)]})],16,rs)),[[S]])],64)}),128)),t.showEmptyMessage&&(!_||_&&_.length===0)?(u(),d("li",w({key:0,class:t.cx("emptyMessage"),role:"option"},t.ptm("emptyMessage")),[P(t.$slots,"empty",{},function(){return[F(y(o.searchResultMessageText),1)]})],16)):b("",!0)],16,ss)]}),_:2},[t.$slots.loader?{name:"loader",fn:ne(function(C){var k=C.options;return[P(t.$slots,"loader",{options:k})]}),key:"0"}:void 0]),1040,["style","items","disabled","pt"])],16),P(t.$slots,"footer",{value:t.d_value,suggestions:o.visibleOptions}),f("span",w({role:"status","aria-live":"polite",class:"p-hidden-accessible"},t.ptm("hiddenSelectedMessage"),{"data-p-hidden-accessible":!0}),y(o.selectedMessageText),17)],16,os)):b("",!0)]}),_:3},16,["onEnter","onAfterEnter","onLeave","onAfterLeave"])]}),_:3},8,["appendTo"])],16,Qo)}Cn.render=ls;function ue(t){return t===void 0?!0:typeof t=="string"?t.trim()==="":typeof t=="object"?Object.keys(t).length===0:!1}function Ce(t){return t===void 0?"":typeof t=="string"?t:JSON.stringify(t)}function us(t,e){if(!e||e==="string"||t.trim()==="")return t;let n;try{n=JSON.parse(t)}catch{throw new Error(`Enter a valid ${e} as JSON`)}if(!(e==="array"?Array.isArray(n):e==="object"?n!==null&&typeof n=="object"&&!Array.isArray(n):e==="integer"?typeof n=="number"&&Number.isInteger(n):typeof n===e))throw new Error(`Enter a valid ${e} as JSON`);return n}const ds={class:"req-value"},cs={class:"req-value-option-main"},ps={class:"mono"},fs={class:"req-value-option-meta"},ms={key:2,role:"alert",class:"req-value-error"},hs=qe({__name:"RequirementValueInput",props:{modelValue:{type:[String,Number,Boolean,Array,Object]},requirement:{},placeholder:{},disabled:{type:Boolean}},emits:["update:model-value","validity","commit"],setup(t,{emit:e}){const n=t,i=e,s=dn(),o=U(Ce(n.modelValue)),c=U([]),p=U(null),m=U(!1);let g=0,h,v=Ce(n.modelValue),S=v,C=!1;on(()=>n.modelValue,z=>{const O=Ce(z);o.value=O,O!==S&&(v=O,S=O,C=!1)});const k=Y(()=>!!n.requirement.expected_type),L=Y(()=>{const z=(n.requirement.suggestions||[]).filter($=>typeof $.value=="string"&&$.value!=="").map($=>({value:$.value,label:$.label||String($.value),source:$.source||"plan",kind:$.kind})),O=new Set(z.map($=>$.value)),D=n.requirement.expected_kind,K=c.value.filter($=>!D||$.kind===D||O.has($.id)).map($=>({value:$.id,label:$.meta?.title||$.id,source:"registry",kind:$.kind})),J=new Set;return[...z,...K].filter($=>J.has($.value)?!1:(J.add($.value),!0)).slice(0,80)});function _(z){o.value=z;try{const O=us(z,n.requirement.expected_type);S=Ce(O),C=S!==v,p.value=null,i("validity",!0),i("update:model-value",O)}catch(O){p.value=O instanceof Error?O.message:"Invalid requirement value",i("validity",!1)}k.value||(h&&clearTimeout(h),h=setTimeout(()=>{M()},180))}async function M(){if(k.value)return;const z=++g;m.value=!0,p.value=null;try{const O=await ni(s,{query:o.value.trim()||void 0,limit:80});z===g&&(c.value=O.entries||[])}catch(O){if(z!==g)return;c.value=[],p.value=O instanceof Error?O.message:"Registry search failed"}finally{z===g&&(m.value=!1)}}function A(){n.disabled||p.value||!C||(v=S,C=!1,i("commit"))}function R(z){n.disabled||_(typeof z=="string"?z:z.value)}function x(z){R(z.value),A()}function B(z){z.target instanceof Element&&z.target.getAttribute("aria-expanded")==="true"&&z.stopPropagation()}return Dn(()=>{g+=1,h&&clearTimeout(h)}),(z,O)=>(u(),d("div",ds,[k.value?(u(),G(W(bt),{key:0,"model-value":o.value,class:"req-value-input mono","aria-label":t.requirement.parameter_name,"aria-invalid":!!p.value,disabled:t.disabled,placeholder:t.placeholder||`Enter ${t.requirement.expected_type}`,"onUpdate:modelValue":O[0]||(O[0]=D=>_(D||"")),onChange:A,onBlur:A,onKeydown:rt(Vn(A,["prevent"]),["enter"])},null,8,["model-value","aria-label","aria-invalid","disabled","placeholder","onKeydown"])):(u(),G(W(Cn),{key:1,"model-value":o.value,suggestions:L.value,"option-label":"value",dropdown:"","complete-on-focus":"",delay:0,"min-length":0,loading:m.value,disabled:t.disabled,placeholder:t.placeholder||"Search registry or type value","input-props":{"aria-label":t.requirement.parameter_name},"input-class":"req-value-input mono",pt:{option:{class:"req-value-option"},dropdown:{"aria-label":"Show requirement candidates"}},"onUpdate:modelValue":R,onComplete:M,onOptionSelect:x,onChange:A,onBlur:A,onKeydown:[rt(A,["enter"]),rt(B,["esc"])]},{option:ne(({option:D})=>[f("span",cs,[f("span",null,y(D.label),1),f("span",ps,y(D.value),1),f("span",fs,y(D.kind||D.source),1)])]),_:1},8,["model-value","suggestions","loading","disabled","placeholder","input-props"])),p.value?(u(),d("p",ms,y(p.value),1)):b("",!0)]))}}),Jt=cn(hs,[["__scopeId","data-v-4d356663"]]),gs={key:0,class:"mt-1 text-[11px]",style:{color:"var(--p-text-color)"}},vs={class:"mono"},ys={class:"flex gap-2"},bs={key:1,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},ws={key:2,role:"alert",class:"mt-1 text-[10px]",style:{color:"var(--p-danger-500)"}},Qt=qe({__name:"RequirementResolution",props:{requirement:{},suggestion:{}},emits:["accept","reject","edit"],setup(t){return(e,n)=>(u(),d(q,null,[t.suggestion?(u(),d("div",gs,[n[3]||(n[3]=f("span",{class:"font-semibold"},"AI",-1)),n[4]||(n[4]=F(" · Pending review: ",-1)),f("span",vs,y(W(Ce)(t.suggestion.value)),1),f("p",null,y(t.suggestion.choice_reason),1),f("div",ys,[f("button",{type:"button",class:"ghost-sm",onClick:n[0]||(n[0]=i=>e.$emit("accept"))},"Accept suggestion"),f("button",{type:"button",class:"ghost-sm",onClick:n[1]||(n[1]=i=>e.$emit("reject"))},"Reject suggestion"),f("button",{type:"button",class:"ghost-sm",onClick:n[2]||(n[2]=i=>e.$emit("edit"))},"Edit suggestion")])])):t.requirement.choice_reason?(u(),d("p",bs,[n[5]||(n[5]=f("span",{class:"font-semibold"},"AI",-1)),F(" · Model suggestion (accepted): "+y(t.requirement.choice_reason),1)])):b("",!0),t.requirement.resolution_error?(u(),d("p",ws,y(t.requirement.resolution_error.code)+": "+y(t.requirement.resolution_error.message)+" Choose a value manually. ",1)):b("",!0)],64))}});var Cs=`
    .p-message {
        display: grid;
        grid-template-rows: 1fr;
        border-radius: dt('message.border.radius');
        outline-width: dt('message.border.width');
        outline-style: solid;
    }

    .p-message-content-wrapper {
        min-height: 0;
    }

    .p-message-content {
        display: flex;
        align-items: center;
        padding: dt('message.content.padding');
        gap: dt('message.content.gap');
    }

    .p-message-icon {
        flex-shrink: 0;
    }

    .p-message-close-button {
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        margin-inline-start: auto;
        overflow: hidden;
        position: relative;
        width: dt('message.close.button.width');
        height: dt('message.close.button.height');
        border-radius: dt('message.close.button.border.radius');
        background: transparent;
        transition:
            background dt('message.transition.duration'),
            color dt('message.transition.duration'),
            outline-color dt('message.transition.duration'),
            box-shadow dt('message.transition.duration'),
            opacity 0.3s;
        outline-color: transparent;
        color: inherit;
        padding: 0;
        border: none;
        cursor: pointer;
        user-select: none;
    }

    .p-message-close-icon {
        font-size: dt('message.close.icon.size');
        width: dt('message.close.icon.size');
        height: dt('message.close.icon.size');
    }

    .p-message-close-button:focus-visible {
        outline-width: dt('message.close.button.focus.ring.width');
        outline-style: dt('message.close.button.focus.ring.style');
        outline-offset: dt('message.close.button.focus.ring.offset');
    }

    .p-message-info {
        background: dt('message.info.background');
        outline-color: dt('message.info.border.color');
        color: dt('message.info.color');
        box-shadow: dt('message.info.shadow');
    }

    .p-message-info .p-message-close-button:focus-visible {
        outline-color: dt('message.info.close.button.focus.ring.color');
        box-shadow: dt('message.info.close.button.focus.ring.shadow');
    }

    .p-message-info .p-message-close-button:hover {
        background: dt('message.info.close.button.hover.background');
    }

    .p-message-info.p-message-outlined {
        color: dt('message.info.outlined.color');
        outline-color: dt('message.info.outlined.border.color');
    }

    .p-message-info.p-message-simple {
        color: dt('message.info.simple.color');
    }

    .p-message-success {
        background: dt('message.success.background');
        outline-color: dt('message.success.border.color');
        color: dt('message.success.color');
        box-shadow: dt('message.success.shadow');
    }

    .p-message-success .p-message-close-button:focus-visible {
        outline-color: dt('message.success.close.button.focus.ring.color');
        box-shadow: dt('message.success.close.button.focus.ring.shadow');
    }

    .p-message-success .p-message-close-button:hover {
        background: dt('message.success.close.button.hover.background');
    }

    .p-message-success.p-message-outlined {
        color: dt('message.success.outlined.color');
        outline-color: dt('message.success.outlined.border.color');
    }

    .p-message-success.p-message-simple {
        color: dt('message.success.simple.color');
    }

    .p-message-warn {
        background: dt('message.warn.background');
        outline-color: dt('message.warn.border.color');
        color: dt('message.warn.color');
        box-shadow: dt('message.warn.shadow');
    }

    .p-message-warn .p-message-close-button:focus-visible {
        outline-color: dt('message.warn.close.button.focus.ring.color');
        box-shadow: dt('message.warn.close.button.focus.ring.shadow');
    }

    .p-message-warn .p-message-close-button:hover {
        background: dt('message.warn.close.button.hover.background');
    }

    .p-message-warn.p-message-outlined {
        color: dt('message.warn.outlined.color');
        outline-color: dt('message.warn.outlined.border.color');
    }

    .p-message-warn.p-message-simple {
        color: dt('message.warn.simple.color');
    }

    .p-message-error {
        background: dt('message.error.background');
        outline-color: dt('message.error.border.color');
        color: dt('message.error.color');
        box-shadow: dt('message.error.shadow');
    }

    .p-message-error .p-message-close-button:focus-visible {
        outline-color: dt('message.error.close.button.focus.ring.color');
        box-shadow: dt('message.error.close.button.focus.ring.shadow');
    }

    .p-message-error .p-message-close-button:hover {
        background: dt('message.error.close.button.hover.background');
    }

    .p-message-error.p-message-outlined {
        color: dt('message.error.outlined.color');
        outline-color: dt('message.error.outlined.border.color');
    }

    .p-message-error.p-message-simple {
        color: dt('message.error.simple.color');
    }

    .p-message-secondary {
        background: dt('message.secondary.background');
        outline-color: dt('message.secondary.border.color');
        color: dt('message.secondary.color');
        box-shadow: dt('message.secondary.shadow');
    }

    .p-message-secondary .p-message-close-button:focus-visible {
        outline-color: dt('message.secondary.close.button.focus.ring.color');
        box-shadow: dt('message.secondary.close.button.focus.ring.shadow');
    }

    .p-message-secondary .p-message-close-button:hover {
        background: dt('message.secondary.close.button.hover.background');
    }

    .p-message-secondary.p-message-outlined {
        color: dt('message.secondary.outlined.color');
        outline-color: dt('message.secondary.outlined.border.color');
    }

    .p-message-secondary.p-message-simple {
        color: dt('message.secondary.simple.color');
    }

    .p-message-contrast {
        background: dt('message.contrast.background');
        outline-color: dt('message.contrast.border.color');
        color: dt('message.contrast.color');
        box-shadow: dt('message.contrast.shadow');
    }

    .p-message-contrast .p-message-close-button:focus-visible {
        outline-color: dt('message.contrast.close.button.focus.ring.color');
        box-shadow: dt('message.contrast.close.button.focus.ring.shadow');
    }

    .p-message-contrast .p-message-close-button:hover {
        background: dt('message.contrast.close.button.hover.background');
    }

    .p-message-contrast.p-message-outlined {
        color: dt('message.contrast.outlined.color');
        outline-color: dt('message.contrast.outlined.border.color');
    }

    .p-message-contrast.p-message-simple {
        color: dt('message.contrast.simple.color');
    }

    .p-message-text {
        font-size: dt('message.text.font.size');
        font-weight: dt('message.text.font.weight');
    }

    .p-message-icon {
        font-size: dt('message.icon.size');
        width: dt('message.icon.size');
        height: dt('message.icon.size');
    }

    .p-message-sm .p-message-content {
        padding: dt('message.content.sm.padding');
    }

    .p-message-sm .p-message-text {
        font-size: dt('message.text.sm.font.size');
    }

    .p-message-sm .p-message-icon {
        font-size: dt('message.icon.sm.size');
        width: dt('message.icon.sm.size');
        height: dt('message.icon.sm.size');
    }

    .p-message-sm .p-message-close-icon {
        font-size: dt('message.close.icon.sm.size');
        width: dt('message.close.icon.sm.size');
        height: dt('message.close.icon.sm.size');
    }

    .p-message-lg .p-message-content {
        padding: dt('message.content.lg.padding');
    }

    .p-message-lg .p-message-text {
        font-size: dt('message.text.lg.font.size');
    }

    .p-message-lg .p-message-icon {
        font-size: dt('message.icon.lg.size');
        width: dt('message.icon.lg.size');
        height: dt('message.icon.lg.size');
    }

    .p-message-lg .p-message-close-icon {
        font-size: dt('message.close.icon.lg.size');
        width: dt('message.close.icon.lg.size');
        height: dt('message.close.icon.lg.size');
    }

    .p-message-outlined {
        background: transparent;
        outline-width: dt('message.outlined.border.width');
    }

    .p-message-simple {
        background: transparent;
        outline-color: transparent;
        box-shadow: none;
    }

    .p-message-simple .p-message-content {
        padding: dt('message.simple.content.padding');
    }

    .p-message-outlined .p-message-close-button:hover,
    .p-message-simple .p-message-close-button:hover {
        background: transparent;
    }

    .p-message-enter-active {
        animation: p-animate-message-enter 0.3s ease-out forwards;
        overflow: hidden;
    }

    .p-message-leave-active {
        animation: p-animate-message-leave 0.15s ease-in forwards;
        overflow: hidden;
    }

    @keyframes p-animate-message-enter {
        from {
            opacity: 0;
            grid-template-rows: 0fr;
        }
        to {
            opacity: 1;
            grid-template-rows: 1fr;
        }
    }

    @keyframes p-animate-message-leave {
        from {
            opacity: 1;
            grid-template-rows: 1fr;
        }
        to {
            opacity: 0;
            margin: 0;
            grid-template-rows: 0fr;
        }
    }
`,Ss={root:function(e){var n=e.props;return["p-message p-component p-message-"+n.severity,{"p-message-outlined":n.variant==="outlined","p-message-simple":n.variant==="simple","p-message-sm":n.size==="small","p-message-lg":n.size==="large"}]},contentWrapper:"p-message-content-wrapper",content:"p-message-content",icon:"p-message-icon",text:"p-message-text",closeButton:"p-message-close-button",closeIcon:"p-message-close-icon"},Os=he.extend({name:"message",style:Cs,classes:Ss}),Is={name:"BaseMessage",extends:He,props:{severity:{type:String,default:"info"},closable:{type:Boolean,default:!1},life:{type:Number,default:null},icon:{type:String,default:void 0},closeIcon:{type:String,default:void 0},closeButtonProps:{type:null,default:null},size:{type:String,default:null},variant:{type:String,default:null}},style:Os,provide:function(){return{$pcMessage:this,$parentInstance:this}}};function Re(t){"@babel/helpers - typeof";return Re=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Re(t)}function qt(t,e,n){return(e=ks(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function ks(t){var e=xs(t,"string");return Re(e)=="symbol"?e:e+""}function xs(t,e){if(Re(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Re(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Sn={name:"Message",extends:Is,inheritAttrs:!1,emits:["close","life-end"],timeout:null,data:function(){return{visible:!0}},mounted:function(){var e=this;this.life&&setTimeout(function(){e.visible=!1,e.$emit("life-end")},this.life)},methods:{close:function(e){this.visible=!1,this.$emit("close",e)}},computed:{closeAriaLabel:function(){return this.$primevue.config.locale.aria?this.$primevue.config.locale.aria.close:void 0},dataP:function(){return me(qt(qt({outlined:this.variant==="outlined",simple:this.variant==="simple"},this.severity,this.severity),this.size,this.size))}},directives:{ripple:vt},components:{TimesIcon:et}};function je(t){"@babel/helpers - typeof";return je=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},je(t)}function en(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function tn(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?en(Object(n),!0).forEach(function(i){$s(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):en(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function $s(t,e,n){return(e=zs(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function zs(t){var e=Ls(t,"string");return je(e)=="symbol"?e:e+""}function Ls(t,e){if(je(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(je(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Ps=["data-p"],_s=["data-p"],Es=["data-p"],Ms=["aria-label","data-p"],As=["data-p"];function Ds(t,e,n,i,s,o){var c=ae("TimesIcon"),p=ht("ripple");return u(),G(gt,w({name:"p-message",appear:""},t.ptmi("transition")),{default:ne(function(){return[s.visible?(u(),d("div",w({key:0,class:t.cx("root"),role:"alert","aria-live":"assertive","aria-atomic":"true","data-p":o.dataP},t.ptm("root")),[f("div",w({class:t.cx("contentWrapper")},t.ptm("contentWrapper")),[t.$slots.container?P(t.$slots,"container",{key:0,closeCallback:o.close}):(u(),d("div",w({key:1,class:t.cx("content"),"data-p":o.dataP},t.ptm("content")),[P(t.$slots,"icon",{class:ee(t.cx("icon"))},function(){return[(u(),G(Ie(t.icon?"span":null),w({class:[t.cx("icon"),t.icon],"data-p":o.dataP},t.ptm("icon")),null,16,["class","data-p"]))]}),t.$slots.default?(u(),d("div",w({key:0,class:t.cx("text"),"data-p":o.dataP},t.ptm("text")),[P(t.$slots,"default")],16,Es)):b("",!0),t.closable?Se((u(),d("button",w({key:1,class:t.cx("closeButton"),"aria-label":o.closeAriaLabel,type:"button",onClick:e[0]||(e[0]=function(m){return o.close(m)}),"data-p":o.dataP},tn(tn({},t.closeButtonProps),t.ptm("closeButton"))),[P(t.$slots,"closeicon",{},function(){return[t.closeIcon?(u(),d("i",w({key:0,class:[t.cx("closeIcon"),t.closeIcon],"data-p":o.dataP},t.ptm("closeIcon")),null,16,As)):(u(),G(c,w({key:1,class:[t.cx("closeIcon"),t.closeIcon],"data-p":o.dataP},t.ptm("closeIcon")),null,16,["class","data-p"]))]})],16,Ms)),[[p]]):b("",!0)],16,_s))],16)],16,Ps)):b("",!0)]}),_:3},16)}Sn.render=Ds;const Vs={key:0},Ts={key:1},Bs={class:"whitespace-pre-wrap break-words text-[11px]"},Qe=qe({__name:"HubRequestError",props:{error:{}},setup(t){const e=t,n=Y(()=>typeof e.error=="string"?{message:e.error}:e.error);return(i,s)=>(u(),G(W(Sn),{severity:"error",closable:!1,class:"mt-2"},{default:ne(()=>[n.value.code?(u(),d("span",Vs,y(n.value.code)+": ",1)):b("",!0),F(y(n.value.message)+" ",1),P(i.$slots,"default"),n.value.details!=null?(u(),d("details",Ts,[s[0]||(s[0]=f("summary",null,"Error details",-1)),f("pre",Bs,y(JSON.stringify(n.value.details,null,2)),1)])):b("",!0)]),_:3}))}}),Fs={class:"dialog-body"},Rs=["for"],js=["id"],Ks=["for"],Hs=["id"],Ns={class:"field-hint"},Us={key:0,class:"mono"},Gs={class:"mt-3 flex items-center justify-between gap-2 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Ws={key:0},Zs={key:1},Ys={class:"text-success-500"},Xs={class:"text-warn-500"},Js={key:2},Qs={class:"flex items-center gap-2"},qs=["disabled"],ea=["disabled"],ta={key:1,role:"status",class:"field-hint"},na={key:2,class:"tree"},ia={class:"tree-indent"},oa={key:0,class:"tree-branch"},sa=["title"],aa={class:"tree-ver mono"},ra={key:0,class:"tree-role"},la=["title"],ua={key:3,class:"legend"},da={key:4,class:"mt-3 mb-3"},ca={class:"form-label flex items-center gap-1.5"},pa={class:"dim"},fa={class:"space-y-2"},ma={class:"flex items-center gap-2 mb-1"},ha={class:"mono text-[11px]",style:{color:"var(--p-text-color)"}},ga={key:0,class:"text-[9px]",style:{color:"var(--p-warn-500)"}},va={key:1,class:"text-[9px]",style:{color:"var(--p-danger-500)"}},ya={key:2,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},ba={key:3,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},wa={key:4,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},Ca={key:0,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Sa={class:"mono"},Oa={key:1,class:"mt-1 text-[10px]",style:{color:"var(--p-danger-500)"}},Ia={key:2,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},ka={key:3,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},xa={key:5,class:"mt-3 mb-3"},$a={class:"form-label flex items-center gap-1.5"},za={class:"dim"},La={class:"space-y-2"},Pa={class:"flex items-center gap-2 mb-1"},_a={class:"mono text-[11px]",style:{color:"var(--p-text-color)"}},Ea={key:0,class:"text-[9px]",style:{color:"var(--p-danger-500)"}},Ma={key:1,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},Aa={key:0,class:"mt-1 text-[10px]",style:{color:"var(--p-danger-500)"}},Da={key:1,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Va={class:"mono"},Ta={key:2,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Ba={key:6,class:"mt-3 mb-3 text-[11px]",style:{color:"var(--p-text-muted-color)"}},Fa={class:"form-check"},Ra={class:"scan-panel"},ja={class:"scan-head"},Ka={class:"scan-title"},Ha={key:0,class:"scan-state"},Na={key:1,class:"scan-summary"},Ua={class:"scan-summary-line"},Ga={class:"mono dim"},Wa={key:0,class:"scan-modules"},Za={class:"mono scan-module-name"},Ya={class:"mono dim"},Xa={key:1,class:"scan-findings"},Ja={class:"scan-finding-title"},Qa={class:"mono dim"},qa={key:0,class:"mono scan-finding-location"},er={key:1,class:"scan-finding-detail"},tr={key:2,class:"scan-state skipped"},nr={key:3,class:"scan-state"},ir={class:"scan-actions"},or=["disabled"],sr=["disabled"],ar={key:7,class:"mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500"},rr={class:"flex justify-end gap-2 mt-4"},lr=["disabled"],ur=["disabled"],dr=qe({__name:"HubInstallDialog",props:{modelValue:{type:Boolean},component:{},initialVersion:{}},emits:["update:modelValue","installed"],setup(t,{emit:e}){const n=t,i=e,s=dn(),o=Vt(),c=Vt(),p=U(""),m=U(""),g=U(!1),h=U(!0),v=U(!1),S=U(null),C=U(!1),k=U(null),L=U(null),_=U(!1);let M=0;const A=we(null),R=U(!1),x=U(!1),B=U(null),z=we([]),O=we({}),D=we({}),K=we({}),J=we({}),$=U({}),Z=U(!1),oe=U(null);let Q=0;function N(){Q+=1,Z.value=!1,R.value=!1,x.value=!1,K.value={},oe.value=null,Et()}const se=U({});on(()=>n.modelValue,r=>{r?ge():N()});function ge(){N(),J.value={},$.value={},p.value=n.initialVersion||"",m.value="",g.value=!1,h.value=!0,v.value=!1,S.value=null,Et(),A.value=null,B.value=null,z.value=[],O.value={},D.value={},x.value=!1,kn(),de()}function xe(){v.value||(N(),i("update:modelValue",!1))}function V(r){return(r.parameter_name||r.full_id||r.name||"").trim()}const $e=Y(()=>{const r=new Set;for(const l of A.value?.graph||[])(l.depth??0)===0&&r.add(l.module);return r});function ve(r){return r.module&&$e.value.size?$e.value.has(r.module):r.transitive!==void 0?!r.transitive:(r.depth??0)===0}const ye=Y(()=>z.value.filter(ve)),Ne=Y(()=>z.value.filter(r=>!ve(r)));function Ue(r){return ue(D.value[V(r)])?r.missing||r.invalid?!0:!!r.required&&ue(r.value):!!r.invalid}const be=Y(()=>Ne.value.filter(Ue));function tt(r){return D.value[V(r)]??r.value??""}function wt(r,l){N();const a=V(r);D.value={...D.value,[a]:l},St(a)}function Ct(r,l){const a=V(r);a&&(O.value[a]!==l&&N(),O.value={...O.value,[a]:l},St(a))}function St(r){const l={...J.value};delete l[r],J.value=l}function Ot(r,l){$.value[V(r)]=l,l||N()}function It(r){return r.expected_type?`Enter ${r.expected_type}${r.expected_type==="string"?"":" as JSON"}`:r.expected_kind?`Enter ${r.expected_kind} id or contract value`:"Enter registry id or contract value"}function kt(){return g.value&&m.value.trim()||void 0}function On(){g.value=!0,N()}const xt=Y(()=>A.value?.dependency?.id||"");function $t(r,l=O.value){A.value=r,Z.value=!0,z.value=r.requirements||[];const a=new Set(z.value.map(V));$.value=Object.fromEntries(Object.entries($.value).filter(([j])=>a.has(j)));const I={};for(const j of ye.value){const te=V(j);te&&(I[te]=j.value??l[te]??"")}O.value=I,D.value=Object.fromEntries((r.install_payload.requirement_bindings||[]).map(j=>[j.name,j.value]))}const zt=Y(()=>z.value.filter(r=>{const l=ve(r)?O.value[V(r)]:tt(r);return ue(l)&&(r.missing||r.value_source==="conflict"||r.suggestions?.length||r.expected_type)}).map(r=>r.full_id||V(r))),Ge=Y(()=>Object.keys(K.value).length);async function In(){const r=[...zt.value];if(!Z.value||!r.length)return;x.value=!0,oe.value=null;const l=Q;try{const a=await li(s,{...it(),requirement_ids:r});if(l!==Q)return;const I=new Set(r),j={},te=new Map(a.requirements.map(E=>[E.full_id||V(E),E]));z.value=z.value.map(E=>{const T=E.full_id||V(E),X=te.get(T);return!I.has(T)||!X?E:(X.value_source==="llm"&&!X.invalid&&!ue(X.value)&&(j[V(E)]=X),{...E,resolution_error:X.resolution_error})}),K.value=j,!Object.keys(j).length&&!a.requirements.some(E=>E.resolution_error)&&(oe.value="No valid AI suggestion is available. Choose a value manually.")}catch(a){l===Q&&(oe.value=Ee(a))}finally{l===Q&&(x.value=!1)}}async function nt(r){const l=r.map(T=>K.value[T]).filter(Boolean);if(!l.length)return;const a={...J.value},I={...K.value};for(const T of r)delete I[T];for(const T of l){const X=V(T);T.value!==void 0&&(ve(T)?O.value={...O.value,[X]:T.value}:D.value={...D.value,[X]:T.value},a[X]=T)}N(),J.value=a;const j=de(),te=Q;if(await j,te!==Q||!Z.value)return;const E={};for(const T of z.value){const X=V(T),ce=I[X];if(!ce||T.expected_type!==ce.expected_type||T.expected_kind!==ce.expected_kind)continue;const Xe=ve(T)?O.value[X]:tt(T);ue(Xe)&&(T.expected_kind&&!T.suggestions?.some(at=>at.value===ce.value)||(E[X]=ce))}K.value=E}function Lt(r){const l={...K.value};delete l[V(r)],K.value=l}function Pt(r){const l=K.value[V(r)];l?.value!==void 0&&(ve(r)?Ct(r,l.value):wt(r,l.value))}function _t(r){return J.value[V(r)]||r}async function de(){if(!n.component.trim())return;N();const r=Q;R.value=!0,B.value=null;const l={...O.value},a=Object.entries(l).filter(([,I])=>!ue(I)).map(([I,j])=>({name:I,value:j}));try{const I=await ri(s,{component:n.component.trim(),version:p.value.trim()||void 0,namespace:kt(),run_migrations:h.value,migration_policy:h.value?"up":"none",parameters:a.length?a:void 0,requirement_bindings:Object.entries(D.value).map(([j,te])=>({name:j,value:te}))});if(r!==Q)return;$t(I,l)}catch(I){if(r!==Q)return;A.value=null,Z.value=!1,B.value=Ee(I)}finally{r===Q&&(R.value=!1)}}async function kn(){try{const r=await si(s,{entries:!1,migrations:!1}),l={};for(const a of r.modules||[])a.name&&a.version&&(l[a.name]=a.version);for(const a of r.dependencies||[]){const I=a.component||a.name;I&&a.version&&!l[I]&&(l[I]=a.version)}se.value=l}catch(r){S.value=Ee(r),se.value={}}}function xn(){const r=[];for(const l of ye.value){const a=V(l);if(!a)continue;const I=O.value[a];!ue(I)&&!l.invalid&&I!==void 0&&r.push({name:a,value:I})}return r.length?r:void 0}function it(){return{component:n.component.trim(),version:p.value.trim()||void 0,namespace:kt(),run_migrations:h.value,migration_policy:h.value?"up":"none",parameters:xn(),requirement_bindings:Object.entries(D.value).map(([r,l])=>({name:r,value:l}))}}const We=Y(()=>{const r=[];for(const l of ye.value){const a=V(l);!a||!l.required&&!l.missing||(l.invalid||ue(O.value[a]))&&r.push(a)}return r});function Et(){M+=1,C.value=!1,k.value=null,L.value=null,_.value=!1}async function $n(){if(!n.component.trim()){k.value="Component required";return}C.value=!0,k.value=null,L.value=null,_.value=!1;const r=M+1;M=r;try{const l=await ui(s,it());r===M&&(L.value=l)}catch(l){if(r!==M)return;k.value=Ee(l)}finally{r===M&&(C.value=!1)}}function zn(){M+=1,C.value=!1,k.value=null,L.value=null,_.value=!0}const Ln=Y(()=>_.value||!!L.value),Mt=Y(()=>!A.value||!Z.value||A.value.applicable===!1||Ge.value>0||Object.values($.value).includes(!1)||v.value||R.value||x.value||C.value||!Ln.value||We.value.length>0||be.value.length>0);function At(r){return(r||"pending").toString().toUpperCase()}function ot(r){const l=(r||"").toString().toLowerCase();return l==="clean"?"clean":l==="critical"?"critical":l==="warnings"||l==="warning"?"warnings":l==="error"?"error":"pending"}function Pn(r){return ot(r.severity)}const st=Y(()=>L.value?.modules||[]),Dt=Y(()=>{const r=[];for(const l of st.value)for(const a of l.findings||[])r.push({...a,module_name:l.module});return r});async function _n(){if(Mt.value){S.value="Review a valid current plan and confirm requirement suggestions before installing";return}if(!n.component.trim()){S.value="Component required";return}if(We.value.length){const r=We.value.length;S.value=`Configure required parameter${r===1?"":"s"}: ${We.value.join(", ")}`;return}if(be.value.length){const r=be.value[0];S.value=`Configure dependency requirement ${V(r)} of ${r.module} before installing`;return}v.value=!0,S.value=null;try{await ai(s,it()),v.value=!1,i("installed",n.component.trim()),xe()}catch(r){const l=r.response?.data;if(l?.code==="PARAMETER_TARGET_TRANSITIVE")S.value=l.error||l.message||"Parameter targets a transitive module; install that module directly with this parameter";else{const a=l?.details;a?.requirements&&a?.install_payload&&$t(a),S.value=Ee(r)}}finally{v.value=!1}}const Ze=Y(()=>{const r=A.value?.graph||[];if(!r.length)return[];const l=new Map,a=[];for(const E of r)if(!E.parent||(E.depth??0)===0)a.push(E);else{const T=l.get(E.parent)||[];T.push(E),l.set(E.parent,T)}const I=[],j=new Set,te=(E,T,X,ce)=>{if(j.has(E.module))return;j.add(E.module),I.push({node:E,depth:T,last:X,guides:ce});const Xe=l.get(E.module)||[];Xe.forEach((at,En)=>{te(at,T+1,En===Xe.length-1,[...ce,!X])})};a.forEach((E,T)=>te(E,0,T===a.length-1,[]));for(const E of r)j.has(E.module)||I.push({node:E,depth:E.depth??0,last:!0,guides:[]});return I});function Ye(r){if(!r.installed)return{kind:"new",label:"NEW",title:"Not installed yet — will be added"};const l=se.value[r.module],a=r.version;return l&&a&&l!==a?{kind:"upgrade",label:`UPGRADE ${l} → ${a}`,title:"Installed at a different version — this install changes it"}:r.shared?{kind:"shared",label:"SHARED",title:"Already installed and reused — reached from another installed module"}:{kind:"installed",label:"INSTALLED",title:"Already installed at this version"}}const pe=Y(()=>{const r=Ze.value;let l=0,a=0,I=0;for(const j of r){const te=Ye(j.node).kind;te==="new"?l++:te==="upgrade"?I++:a++}return{added:l,reused:a,upgraded:I,total:r.length}});return(r,l)=>(u(),G(nn,{to:"body"},[H(W(mn),{visible:t.modelValue,modal:"",draggable:!1,closable:!v.value,"close-on-escape":!v.value,header:`Install ${t.component}`,class:"keeper-install-dialog",style:{width:"600px",maxWidth:"95vw"},"onUpdate:visible":xe},{default:ne(()=>[f("div",Fs,[l[20]||(l[20]=f("p",{class:"text-[11px] mb-3 leading-relaxed",style:{color:"var(--p-text-muted-color)"}}," Installs a component from the hub and applies its registry entries. The plan below resolves the full dependency tree before anything changes. ",-1)),f("label",{for:W(o),class:"form-label"},"Version",8,Rs),Se(f("input",{id:W(o),"onUpdate:modelValue":l[0]||(l[0]=a=>p.value=a),placeholder:"latest",class:"form-input mono",onInput:N,onChange:de},null,40,js),[[Tt,p.value]]),f("label",{for:W(c),class:"form-label mt-3"},"Dependency namespace",8,Ks),Se(f("input",{id:W(c),"onUpdate:modelValue":l[1]||(l[1]=a=>m.value=a),placeholder:"auto",class:"form-input mono",onInput:On,onChange:de},null,40,Hs),[[Tt,m.value]]),f("div",Ns,[l[4]||(l[4]=F(" Auto target uses an existing dependency entry or the strongest dependency namespace cluster. ",-1)),xt.value?(u(),d("span",Us,y(xt.value),1)):b("",!0)]),f("div",Gs,[R.value?(u(),d("span",Ws,"Resolving install plan…")):A.value?(u(),d("span",Zs,[F(y(pe.value.total)+" module"+y(pe.value.total===1?"":"s")+" · ",1),f("span",Ys,y(pe.value.added)+" new",1),pe.value.upgraded?(u(),d(q,{key:0},[l[5]||(l[5]=F(" · ",-1)),f("span",Xs,y(pe.value.upgraded)+" upgrade",1)],64)):b("",!0),pe.value.reused?(u(),d(q,{key:1},[F(" · "+y(pe.value.reused)+" reused",1)],64)):b("",!0)])):(u(),d("span",Js,"Plan resolves transitive dependencies before install.")),f("div",Qs,[zt.value.length?(u(),d("button",{key:0,class:"ghost-sm",type:"button",onClick:In,disabled:!Z.value||R.value||x.value||v.value},y(x.value?"Suggesting…":"Suggest with AI"),9,qs)):b("",!0),f("button",{class:"ghost-sm",type:"button",onClick:de,disabled:R.value||x.value},"Refresh",8,ea)])]),oe.value?(u(),G(Qe,{key:0,error:oe.value},{default:ne(()=>[...l[6]||(l[6]=[F(" You can enter values manually.",-1)])]),_:1},8,["error"])):b("",!0),Ge.value?(u(),d("div",ta,[F(" Review "+y(Ge.value)+" AI suggestion"+y(Ge.value===1?"":"s")+" before applying. ",1),f("button",{type:"button",class:"ghost-sm",onClick:l[2]||(l[2]=a=>nt(Object.keys(K.value)))},"Accept all")])):b("",!0),Ze.value.length?(u(),d("div",na,[(u(!0),d(q,null,re(Ze.value,a=>(u(),d("div",{key:a.node.path||a.node.module,class:"tree-row"},[f("span",ia,[(u(!0),d(q,null,re(a.guides,(I,j)=>(u(),d("span",{key:j,class:ee(["tree-guide",{on:I}])},null,2))),128)),a.depth>0?(u(),d("span",oa,y(a.last?"└":"├"),1)):b("",!0)]),f("span",{class:ee(["tree-name mono",{direct:a.node.direct}]),title:a.node.module},y(a.node.module),11,sa),f("span",aa,y(a.node.version||a.node.constraint||""),1),a.node.direct?(u(),d("span",ra,"direct")):b("",!0),f("span",{class:ee(["node-badge",Ye(a.node).kind]),title:Ye(a.node).title},y(Ye(a.node).label),11,la)]))),128))])):b("",!0),Ze.value.length?(u(),d("div",ua,[...l[7]||(l[7]=[f("span",{class:"node-badge new"},"NEW",-1),f("span",{class:"legend-txt"},"added by this install",-1),f("span",{class:"node-badge upgrade"},"UPGRADE",-1),f("span",{class:"legend-txt"},"installed version changes",-1),f("span",{class:"node-badge shared"},"SHARED",-1),f("span",{class:"legend-txt"},"already installed, reused",-1),f("span",{class:"node-badge installed"},"INSTALLED",-1),f("span",{class:"legend-txt"},"present, unchanged",-1)])])):b("",!0),ye.value.length?(u(),d("div",da,[f("div",ca,[H(W(le),{icon:"tabler:list-check",class:"w-3.5 h-3.5"}),l[8]||(l[8]=F(" Configuration ",-1)),f("span",pa,"("+y(ye.value.length)+")",1)]),f("div",fa,[(u(!0),d(q,null,re(ye.value,a=>(u(),d("label",{key:a.parameter_name||a.name,class:"block"},[f("div",ma,[f("span",ha,y(a.parameter_name||a.name),1),a.required?(u(),d("span",ga,"required")):b("",!0),a.invalid?(u(),d("span",va,"invalid")):b("",!0),a.value_source&&a.value_source!=="empty"?(u(),d("span",ya,y(a.value_source),1)):b("",!0),a.expected_kind?(u(),d("span",ba,y(a.expected_kind),1)):b("",!0),a.targets?.length?(u(),d("span",wa,y(a.targets.length)+" target"+y(a.targets.length===1?"":"s"),1)):b("",!0)]),H(Jt,{"model-value":O.value[V(a)]??"",requirement:a,placeholder:It(a),"onUpdate:modelValue":I=>Ct(a,I),onCommit:de,onValidity:I=>Ot(a,I)},null,8,["model-value","requirement","placeholder","onUpdate:modelValue","onValidity"]),!W(ue)(a.default)&&a.value_source!=="default"?(u(),d("div",Ca,[l[9]||(l[9]=F("Package default: ",-1)),f("span",Sa,y(W(Ce)(a.default)),1)])):b("",!0),a.invalid_reason?(u(),d("div",Oa,y(a.invalid_reason),1)):b("",!0),H(Qt,{requirement:_t(a),suggestion:K.value[V(a)],onAccept:I=>nt([V(a)]),onReject:I=>Lt(a),onEdit:I=>Pt(a)},null,8,["requirement","suggestion","onAccept","onReject","onEdit"]),a.module?(u(),d("div",Ia,y(a.module)+y(a.version?"@"+a.version:""),1)):b("",!0),a.description?(u(),d("div",ka,y(a.description),1)):b("",!0)]))),128))])])):b("",!0),Ne.value.length?(u(),d("div",xa,[f("div",$a,[H(W(le),{icon:"tabler:sitemap",class:"w-3.5 h-3.5"}),l[10]||(l[10]=F(" Dependency configuration ",-1)),f("span",za,"("+y(Ne.value.length)+")",1)]),f("div",La,[(u(!0),d(q,null,re(Ne.value,a=>(u(),d("div",{key:a.parameter_name||a.name,class:ee(["transitive-req",{blocked:Ue(a)}])},[f("div",Pa,[f("span",_a,y(a.parameter_name||a.name),1),l[11]||(l[11]=f("span",{class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},"transitive",-1)),Ue(a)?(u(),d("span",Ea,"unsatisfied")):a.value_source&&a.value_source!=="empty"?(u(),d("span",Ma,y(a.value_source),1)):b("",!0)]),H(Jt,{"model-value":tt(a),requirement:a,disabled:v.value||R.value||x.value,placeholder:It(a),"onUpdate:modelValue":I=>wt(a,I),onCommit:de,onValidity:I=>Ot(a,I)},null,8,["model-value","requirement","disabled","placeholder","onUpdate:modelValue","onValidity"]),H(Qt,{requirement:_t(a),suggestion:K.value[V(a)],onAccept:I=>nt([V(a)]),onReject:I=>Lt(a),onEdit:I=>Pt(a)},null,8,["requirement","suggestion","onAccept","onReject","onEdit"]),Ue(a)?(u(),d("div",Aa,y(a.invalid_reason||"No value satisfies this requirement."),1)):(u(),d("div",Da,[l[12]||(l[12]=F(" Applies to ",-1)),f("span",Va,y(a.module),1),l[13]||(l[13]=F(" through its dependency binding. ",-1))])),a.description?(u(),d("div",Ta,y(a.description),1)):b("",!0)],2))),128))])])):b("",!0),A.value&&!R.value&&!z.value.length?(u(),d("div",Ba," No configuration required. ")):b("",!0),f("label",Fa,[Se(f("input",{"onUpdate:modelValue":l[3]||(l[3]=a=>h.value=a),type:"checkbox",onChange:de},null,544),[[Tn,h.value]]),l[14]||(l[14]=F(" Run migrations after install ",-1))]),f("section",Ra,[f("div",ja,[f("div",Ka,[H(W(le),{icon:"tabler:shield-check",class:"w-3.5 h-3.5"}),l[15]||(l[15]=F(" Security review ",-1))]),f("span",{class:ee(["scan-badge",_.value?"skipped":ot(L.value?.overall_status)])},y(_.value?"SKIPPED":L.value?At(L.value.overall_status):C.value?"RUNNING":"PENDING"),3)]),C.value?(u(),d("div",Ha,[H(W(le),{icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin"}),F(" Reviewing "+y(t.component)+" before install ",1)])):L.value?(u(),d("div",Na,[f("div",Ua,[F(y(L.value.overall_summary)+" ",1),f("span",Ga,y(L.value.scanned)+"/"+y(L.value.total),1)]),st.value.length?(u(),d("div",Wa,[(u(!0),d(q,null,re(st.value,a=>(u(),d("div",{key:a.module,class:"scan-module"},[f("span",Za,y(a.module),1),f("span",Ya,y(a.version||""),1),f("span",{class:ee(["scan-mini-badge",ot(a.status)])},y(At(a.status)),3)]))),128))])):b("",!0),Dt.value.length?(u(),d("div",Xa,[(u(!0),d(q,null,re(Dt.value,(a,I)=>(u(),d("div",{key:I,class:ee(["scan-finding",Pn(a)])},[f("div",Ja,[f("span",null,y(a.title),1),f("span",Qa,y(a.module_name),1)]),a.location?(u(),d("div",qa,y(a.location),1)):b("",!0),a.detail?(u(),d("div",er,y(a.detail),1)):b("",!0)],2))),128))])):b("",!0)])):_.value?(u(),d("div",tr,[H(W(le),{icon:"tabler:shield-off",class:"w-3.5 h-3.5"}),l[16]||(l[16]=F(" Install will continue without a security review. ",-1))])):(u(),d("div",nr,[H(W(le),{icon:"tabler:shield-question",class:"w-3.5 h-3.5"}),l[17]||(l[17]=F(" Choose a security review path before installing. ",-1))])),k.value?(u(),G(Qe,{key:4,error:k.value},null,8,["error"])):b("",!0),f("div",ir,[f("button",{class:"scan-btn primary",type:"button",onClick:$n,disabled:C.value||v.value||R.value},[H(W(le),{icon:C.value?"tabler:loader-2":"tabler:shield-search",class:ee(["w-3.5 h-3.5",{"animate-spin":C.value}])},null,8,["icon","class"]),F(" "+y(L.value?"Run again":"Run scan"),1)],8,or),f("button",{class:"scan-btn secondary",type:"button",onClick:zn,disabled:C.value||v.value},[H(W(le),{icon:"tabler:player-skip-forward",class:"w-3.5 h-3.5"}),l[18]||(l[18]=F(" Skip ",-1))],8,sr)])]),be.value.length?(u(),d("div",ar,y(be.value.length)+" dependency requirement"+y(be.value.length===1?" is":"s are")+" unsatisfied. Choose a compatible value before installing. ",1)):b("",!0),B.value?(u(),G(Qe,{key:8,error:B.value},null,8,["error"])):b("",!0),S.value?(u(),G(Qe,{key:9,error:S.value},null,8,["error"])):b("",!0),f("div",rr,[f("button",{class:"dialog-btn cancel",onClick:xe,disabled:v.value},"Cancel",8,lr),f("button",{class:"dialog-btn proceed",onClick:_n,disabled:Mt.value},[v.value?(u(),G(W(le),{key:0,icon:"tabler:loader-2",class:"w-3 h-3 animate-spin"})):b("",!0),l[19]||(l[19]=F(" Install ",-1))],8,ur)])])]),_:1},8,["visible","closable","close-on-escape","header"])]))}}),Cr=cn(dr,[["__scopeId","data-v-b16342da"]]);export{Cr as H,gr as a,yr as b,br as c,wr as g,si as l,hr as p,vr as r,mr as u};
