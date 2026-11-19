(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const COLS=[rgba(.1,.6,.95),rgba(.85,.2,.7)];
const hit=(b,p,dx,dy)=>Math.abs(p.x-b.x)<=b.w/2+dx&&Math.abs(p.y-b.y)<=b.h/2+dy;
class CompareGame extends MiniScene{
 setupGame(){this.duration=30;this.states=[];
  for(const s of this.seats){const st={rand:this.newRand(),count:0,vals:[0,0],btns:[],labels:[],timeLeft:3,timeMax:3,streak:0,lock:0,cpuTimer:0,active:false};
   const top=s.h/2-40,bottom=-s.h/2+12,barH=10;st.barW=s.w-28;
   const bg=new Sprite(null,st.barW,barH,white(1,.12));bg.y=top-8;bg.z=2;s.field.add(bg);
   const bar=new Sprite(null,st.barW,barH,Theme.green);bar.ax=0;bar.x=-st.barW/2;bar.y=top-8;bar.z=3;s.field.add(bar);st.bar=bar;
   const areaTop=top-28,areaBot=bottom+22,vertical=s.w<300,bw=vertical?s.w-28:(s.w-40)/2,bh=vertical?(areaTop-areaBot-10)/2:Math.min(areaTop-areaBot,bw*1.1);
   for(let i=0;i<2;i++){const b=this.button('',bw,bh,COLS[i],'#fff',20);if(vertical){b.x=0;b.y=areaTop-bh/2-i*(bh+10)}else{b.x=(i===0?-1:1)*(bw/2+6);b.y=(areaTop+areaBot)/2}b.z=4;s.field.add(b);
    const l=label('',Math.min(44,bw*.3,bh*.5),'#fff');l.x=b.x;l.y=b.y;l.z=6;s.field.add(l);st.btns.push(b);st.labels.push(l)}
   const sl=label('',13,'#ff0');sl.y=bottom+8;sl.z=6;s.field.add(sl);st.streakLabel=sl;
   const hint=label('TIPPE DIE GRÖSSERE ZAHL',Math.min(15,s.w*.07),'#fff');hint.y=(areaTop+areaBot)/2+(vertical?0:bh/2+6);hint.z=8;hint.run(A.sequence([A.wait(3.4),A.fadeOut(.5)]));if(!vertical)hint.y=areaTop-4;s.field.add(hint);
   this.states.push(st)}}
 gameStarted(){for(const s of this.seats)this.nextQuestion(s)}
 text(v,expr,r){if(!expr)return''+v;const divs=[];for(let d=2;d<=9;d++)if(v%d===0&&v/d>=2)divs.push(d);
  if(divs.length&&r.chance(.6)){const d=r.pick(divs);return d+'×'+(v/d)}const x=r.int(1,Math.max(1,v-1));return x+'+'+(v-x)}
 nextQuestion(s){const st=this.states[s.index],r=st.rand,lvl=st.count,maxV=Math.min(20+lvl*6,99),gap=Math.max(1,9-lvl),a=r.int(10,maxV);
  let b=a+(r.chance(.5)?1:-1)*r.int(1,gap+(lvl<3?6:0));if(b===a)b=a+1;
  const ec=lvl<5?0:Math.min(.8,.3+(lvl-5)*.08),ea=r.chance(ec),eb=r.chance(ec),swap=r.chance(.5),pair=swap?[b,a]:[a,b];st.vals=pair;
  st.labels[0].text=this.text(pair[0],ea,r);st.labels[1].text=this.text(pair[1],eb,r);
  for(let i=0;i<2;i++){st.btns[i].setScale(.85);st.btns[i].run(A.scaleTo(1,.1));st.labels[i].setScale(.85);st.labels[i].run(A.scaleTo(1,.1))}
  st.timeMax=Math.max(1.5,3.4-lvl*.1);st.timeLeft=st.timeMax;st.active=true;if(s.isCPU)st.cpuTimer=.6+(1-s.skill)*1.3+lvl*.03+Math.random()*.3}
 gameUpdate(dt){for(const s of this.seats){const st=this.states[s.index];if(!st.active)continue;if(st.lock>0){st.lock-=dt;continue}
  st.timeLeft-=dt;const f=Math.max(0,st.timeLeft/st.timeMax);st.bar.w=st.barW*f;st.bar.color=f>.5?Theme.green:(f>.25?'#ff0':'#f00');
  if(st.timeLeft<=0){this.miss(s,true);continue}
  if(s.isCPU){st.cpuTimer-=dt;if(st.cpuTimer<=0){const right=st.vals[0]>st.vals[1]?0:1,ok=Math.random()<.6+s.skill*.36;this.choose(s,ok?right:1-right)}}}}
 miss(s,timeout){const st=this.states[s.index];st.streak=0;st.streakLabel.text='';st.active=false;st.count++;this.setScore(s,Math.max(0,s.score-1));s.shake(4);s.flash('#f00',.35);
  s.floatText(timeout?'ZU LANGSAM −1':'−1',{x:0,y:0},'#f33',22);if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}
  const right=st.vals[0]>st.vals[1]?0:1;st.btns[right].run(A.sequence([A.scaleTo(1.1,.1),A.scaleTo(1,.1)]));
  this.run(A.sequence([A.wait(.5),A.run(()=>{if(this.phase==='playing')this.nextQuestion(s)})]));st.lock=.5}
 choose(s,i){const st=this.states[s.index];if(!st.active||st.lock>0)return;const right=st.vals[0]>st.vals[1]?0:1;
  if(i===right){st.streak++;const pts=st.streak>0&&st.streak%4===0?2:1;this.addScore(s,pts);this.addStat('hits',1,s);st.count++;st.active=false;
   const b=st.btns[i];s.burst({x:b.x,y:b.y},'#fff',8,140);s.floatText(pts>1?'+2 SERIE!':'+1',{x:b.x,y:b.y+36},pts>1?'#ff0':Theme.green,pts>1?24:20);
   st.streakLabel.text=st.streak>=3?'🔥 '+st.streak+'er Serie':'';if(!s.isCPU){Sfx.play(pts>1?'coin':'right');Haptic.tap()}this.nextQuestion(s)}
  else this.miss(s,false)}
 began(seat,at){const st=this.states[seat.index];for(let i=0;i<2;i++)if(hit(st.btns[i],at,4,6)){this.choose(seat,i);return}}
}
Arcade.register('compare',CompareGame);
})();
