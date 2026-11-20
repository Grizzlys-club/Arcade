(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
const ROUNDS=5;
class PumpGame extends MiniScene{
 setupGame(){this.duration=0;this.round=0;this.stage='play';this.timer=0;this.thr=[];this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),st={p,n:0,state:'idle',bank:0,cpu:.5,rt:3+Math.random()*3};
  const bl=new Sprite(Gfx.circle(34,white(1,.9),'#fff'),68,68);bl.x=0;bl.y=p.cy+20;bl.z=4;bl.cbf=1;bl.color=s.color;s.field.add(bl);st.bl=bl;
  const hl=new Sprite(Gfx.circle(14,white(1,.5),null),28,28);hl.x=-12;hl.y=p.cy+34;hl.z=5;s.field.add(hl);st.hl=hl;
  const bk=new Sprite(Gfx.pill(p.w-40,54,'rgba(61,255,122,.9)','#fff',27,false),p.w-40,54);bk.y=p.cy-p.h/2+42;bk.z=6;s.field.add(bk);st.bk=bk;
  const bt=label('KASSIEREN',20,'#03260f');bt.y=bk.y;bt.z=7;s.field.add(bt);
  st.info=label('',20,'#fff');st.info.y=p.cy+p.h/2-22;st.info.z=9;s.field.add(st.info);st.pts=label('0',34,'#fff');st.pts.y=p.cy+p.h/2-62;st.pts.z=9;s.field.add(st.pts);
  st.rl=label('RUNDE 1/'+ROUNDS,12,white(1,.6));st.rl.x=-p.w/2+48;st.rl.y=p.cy+p.h/2-16;st.rl.z=9;s.field.add(st.rl);
  if(!s.isCPU){const h=label('TIPPEN = PUMPEN – RECHTZEITIG KASSIEREN',11,white(1,.7));h.y=p.cy-10;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(6),A.fadeOut(.5),A.remove()]))}return st})}
 gameStarted(){this.startRound()}
 startRound(){this.round++;this.stage='play';for(const s of this.seats){const st=this.st[s.index];st.n=0;st.state='play';st.thr=7+Math.floor(Math.random()*18);st.bl.alpha=1;st.bl.sx=st.bl.sy=1;st.bl.rot=0;st.bk.alpha=1;st.info.text='';st.pts.text='0';st.rl.text='RUNDE '+this.round+'/'+ROUNDS;st.cpu=.5;st.cpuStop=Math.floor(4+NK.rr(0,9)*(.5+s.skill*.7))}}
 gameUpdate(dt){if(this.stage==='play'){for(const s of this.seats){const st=this.st[s.index];if(st.state!=='play')continue;if(s.isCPU){st.cpu-=dt;if(st.cpu<=0){st.cpu=NK.rr(.25,.5);if(st.n>=st.cpuStop)this.bank(s);else this.pump(s)}}}
  if(this.seats.every(s=>this.st[s.index].state!=='play')){this.stage='gap';this.timer=1.6}}
  else if(this.stage==='gap'){this.timer-=dt;if(this.timer<=0){if(this.round>=ROUNDS)this.finishGame();else this.startRound()}}
  for(const s of this.seats){const st=this.st[s.index];if(st.state==='play'||st.state==='bank'){const sc=1+st.n*.09;st.bl.sx+=(sc-st.bl.sx)*Math.min(1,dt*14);st.bl.sy=st.bl.sx;if(st.state==='play'&&st.n>st.thr-5){st.bl.rot=Math.sin(this.elapsed*40)*.05*(st.n-st.thr+6)}}}}
 began(s,at){const st=this.st[s.index];if(st.state!=='play')return;if(at.y<st.p.cy-st.p.h/2+75)this.bank(s);else this.pump(s)}
 pump(s){const st=this.st[s.index];if(st.state!=='play')return;st.n++;Sfx.play('tick');if(!s.isCPU)Haptic.tap('light');st.pts.text=''+st.n;const pos={x:0,y:st.p.cy+20};
  if(st.n>st.thr){st.state='pop';st.bl.alpha=0;s.burst(pos,s.color,30,200);NK.ring(s,pos,s.color,30,.4);s.flash('#f00',.3);s.shake(8);Sfx.play('hit');Haptic.bad&&!s.isCPU&&Haptic.bad();st.info.text='PLATZT! 0 PUNKTE';st.bk.alpha=.2}}
 bank(s){const st=this.st[s.index];if(st.state!=='play'||st.n<1)return;st.state='bank';this.addScore(s,st.n);this.addStat('hits',1,s);st.info.text='+'+st.n+' KASSIERT';s.floatText('+'+st.n,{x:0,y:st.p.cy+90},'#ff0',26);Sfx.play('coin');st.bk.alpha=.3;st.bl.run(A.sequence([A.scaleTo(1.2,.1),A.scaleTo(1,.1)]))}
}
Arcade.register('pump',PumpGame);})();
