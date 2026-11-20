(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const LC=[rgba(.2,.85,1),rgba(1,.3,.75),rgba(1,.85,.25),rgba(.35,1,.5)];
const FALL=1.4,BEAT=.5,PERF=.075,GOOD=.16,CATCH=.28;
class RhythmGame extends MiniScene{
 setupGame(){this.duration=40;this.lanes=this.n<=2?4:3;this.pattern=[];this.lastBeat=-1;const r=this.newRand();let t=1.9,last=-1,k=0;const step=BEAT/2;
  while(t<37.8){const prog=t/38,onBeat=k%2===0,p=(onBeat?.64:.27)*(.65+.5*prog);
   if(r.chance(p)){let lane=r.int(0,this.lanes-1);if(lane===last)lane=(lane+r.int(1,this.lanes-1))%this.lanes;this.pattern.push({t,lane});last=lane;
    if(prog>.45&&r.chance(.12)){const l2=(lane+r.int(1,this.lanes-1))%this.lanes;this.pattern.push({t,lane:l2})}}
   t+=step;k++}
  this.states=[];for(const s of this.seats){const st={notes:[],nextIdx:0,combo:0,laneX:[],receptors:[],recGlow:[],noteTex:[]};this.buildSeat(s,st);this.states.push(st)}}
 buildSeat(s,st){const innerW=s.w-12,laneW=innerW/this.lanes;st.laneW=laneW;st.hitY=-s.h/2+64;st.topY=s.h/2-62;st.speed=(st.topY-st.hitY)/FALL;const laneH=st.topY-st.hitY+70,recR=Math.min(laneW*.4,22);
  for(let i=0;i<this.lanes;i++){const c=LC[i%4],x=-innerW/2+laneW*(i+.5);st.laneX.push(x);
   const bg=new Sprite(Gfx.rect(laneW-4,laneH,alpha(c,.09),8),laneW-4,laneH);bg.x=x;bg.y=st.hitY-28+laneH/2;bg.z=1;s.field.add(bg);
   const edge=new Sprite(null,1.5,laneH,alpha(c,.25));edge.x=x-laneW/2+1;edge.y=bg.y;edge.z=2;s.field.add(edge);
   const glow=new Sprite(Gfx.glow(),recR*4.2,recR*4.2);glow.color=c;glow.cbf=1;glow.blend='add';glow.alpha=0;glow.x=x;glow.y=st.hitY;glow.z=4;s.field.add(glow);st.recGlow.push(glow);
   const rec=new Sprite(Gfx.circle(recR,alpha(c,.2),c),recR*2,recR*2);rec.x=x;rec.y=st.hitY;rec.z=5;s.field.add(rec);st.receptors.push(rec);
   st.noteTex.push(Gfx.pill(laneW-12,20,c,'#fff',10))}
  const line=new Sprite(null,innerW,2,white(1,.35));line.y=st.hitY;line.z=3;s.field.add(line);st.hitLine=line;
  const bear=this.makeBear(s,32,false);bear.y=-s.h/2+6;bear.z=6;s.field.add(bear);bear.startBob(2,.25);st.bear=bear;
  const combo=label('',s.w<250?15:18,'#fff');combo.y=s.h/2-38;combo.z=410;s.node.add(combo);st.comboLabel=combo;
  if(!s.isCPU){const hint=label('TIPPE IM TAKT',13,white(1,.75));hint.y=st.hitY+60;hint.z=410;s.node.add(hint);hint.run(A.sequence([A.wait(6),A.fadeOut(.5),A.remove()]))}}
 began(seat,at){const st=this.states[seat.index];let best=0,bd=1e9;st.laneX.forEach((lx,i)=>{const d=Math.abs(lx-at.x);if(d<bd){bd=d;best=i}});this.press(best,seat,st);this.tapJudge(seat,st,best)}
 press(lane,seat,st){const rec=st.receptors[lane];if(!rec)return;rec.removeAction('p');rec.run(A.sequence([A.scaleTo(1.25,.04),A.scaleTo(1,.1)]),'p');const g=st.recGlow[lane];g.removeAction('g');g.alpha=.7;g.run(A.fadeOut(.25),'g')}
 tapJudge(seat,st,lane){let best=null,bd=99;for(const nt of st.notes){if(!nt.done&&!nt.missed&&nt.def.lane===lane){const d=Math.abs(nt.def.t-this.elapsed);if(d<CATCH&&d<bd){bd=d;best=nt}}}
  if(best)this.resolve(seat,st,best,best.def.t-this.elapsed);else{if(st.combo>0)this.breakCombo(seat,st);Sfx.play('tap')}}
 resolve(s,st,nt,err){const a=Math.abs(err),x=st.laneX[nt.def.lane];if(a>GOOD){nt.missed=true;this.markMiss(s,st,nt);return}
  const perfect=a<=PERF,mult=Math.min(3,1+Math.floor(st.combo/10)),pts=(perfect?3:1)*mult;st.combo++;const nm=Math.min(3,1+Math.floor(st.combo/10));
  this.addScore(s,pts);this.addStat('hits',1,s);nt.done=true;const c=LC[nt.def.lane%4];
  nt.node.run(A.sequence([A.group([A.scaleTo(1.6,.12),A.fadeOut(.12)]),A.remove()]));
  s.burst({x,y:st.hitY},perfect?'#ff0':c,perfect?18:8,perfect?110:70);
  // Extra: Lichtstrahl nach oben
  const beam=new Sprite(Gfx.glow(),st.laneW*.9,s.h*.7);beam.color=perfect?'#ff0':c;beam.cbf=1;beam.blend='add';beam.alpha=.5;beam.x=x;beam.y=st.hitY+s.h*.3;beam.z=2;s.field.add(beam);beam.run(A.sequence([A.fadeOut(.25),A.remove()]));
  s.floatText(perfect?'PERFEKT':'GUT',{x,y:st.hitY+34},perfect?'#ff0':'#fff',s.w<250?12:15);
  if(perfect){Sfx.play('coin');if(!s.isCPU)Haptic.tap('medium');st.bear.squash()}else{Sfx.play('tap');if(!s.isCPU)Haptic.tap('light')}
  if(nm>mult){s.banner('x'+nm,'#ff0',34,.4);s.flash('#ff0',.15)}this.updateCombo(s,st)}
 markMiss(s,st,nt){nt.node.removeAllActions();nt.node.cbf=.8;nt.node.color=rgba(.35,.05,.1);nt.node.alpha=.55;this.breakCombo(s,st);s.floatText('MISS',{x:st.laneX[nt.def.lane],y:st.hitY+30},rgba(1,.35,.35),s.w<250?11:14);Sfx.play('miss')}
 breakCombo(s,st){const had=st.combo;st.combo=0;this.updateCombo(s,st);if(had>=5){s.flash('#f00',.18,.25);if(!s.isCPU)Haptic.bad()}}
 updateCombo(s,st){const l=st.comboLabel;if(st.combo>=2){const m=Math.min(3,1+Math.floor(st.combo/10));l.text=st.combo+' COMBO  x'+m;l.color=m===3?'#ff0':(m===2?Theme.orange:'#fff');l.removeAction('pop');l.setScale(1);l.run(A.sequence([A.scaleTo(1.2,.05),A.scaleTo(1,.08)]),'pop')}else l.text=''}
 gameUpdate(dt){const beat=Math.floor(this.elapsed/BEAT);
  if(beat!==this.lastBeat){this.lastBeat=beat;Sfx.play('tick');for(const st of this.states){const l=st.hitLine;l.removeAction('beat');l.alpha=1;l.run(A.fadeTo(.55,.25),'beat');l.run(A.sequence([A.scaleYTo(2.5,.04),A.scaleYTo(1,.2)]),'beatS')}}
  for(const s of this.seats){const st=this.states[s.index];
   while(st.nextIdx<this.pattern.length&&this.pattern[st.nextIdx].t-FALL<=this.elapsed){const def=this.pattern[st.nextIdx++],node=new Sprite(st.noteTex[def.lane],st.laneW-12,20);node.x=st.laneX[def.lane];node.y=st.topY;node.z=8;node.alpha=0;
    const g=new Sprite(Gfx.glow(),st.laneW+10,56);g.color=LC[def.lane%4];g.cbf=1;g.blend='add';g.alpha=.6;g.z=-1;node.add(g);s.field.add(node);const nt={def,node,done:false,missed:false,cpuAt:null};
    if(s.isCPU){const mc=(1-s.skill)*.45+.03;if(Math.random()>=mc){const sp=.02+(1-s.skill)*.15,e=(Math.random()*2-1+Math.random()*2-1)*.5*sp;nt.cpuAt=def.t+e}}
    st.notes.push(nt)}
   for(let i=st.notes.length-1;i>=0;i--){const nt=st.notes[i];if(nt.done){st.notes.splice(i,1);continue}
    const dtn=nt.def.t-this.elapsed;nt.node.y=st.hitY+dtn*st.speed;if(!nt.missed)nt.node.alpha=Math.min(1,(FALL-dtn)/.25);
    if(s.isCPU&&nt.cpuAt!==null&&!nt.missed&&this.elapsed>=nt.cpuAt){nt.cpuAt=null;this.press(nt.def.lane,s,st);this.resolve(s,st,nt,nt.def.t-this.elapsed);if(nt.done){st.notes.splice(i,1);continue}}
    if(!nt.missed&&-dtn>GOOD){nt.missed=true;this.markMiss(s,st,nt)}
    if(-dtn>.7){nt.node.removeFromParent();st.notes.splice(i,1)}}}}
}
Arcade.register('rhythm',RhythmGame);
})();
