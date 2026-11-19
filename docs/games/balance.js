(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const MAXTILT=.38,G=420,BALLR=11,BEAMT=10;
class BalanceGame extends MiniScene{
 beamL(s){return s.w*.8}pivot(s){return{x:0,y:-s.h*.1}}
 setupGame(){this.duration=60;this.states=[];
  for(const s of this.seats){const L=this.beamL(s),p=this.pivot(s);
   const stand=new Sprite(Gfx.texture('balance_stand',40,60,2,c=>{c.fillStyle=white(.85);c.beginPath();c.moveTo(20,0);c.lineTo(40,60);c.lineTo(0,60);c.closePath();c.fill()}),34,52);stand.ay=1;stand.x=p.x;stand.y=p.y;stand.z=2;s.field.add(stand);
   const floor=new Sprite(null,s.w,6,rgba(.6,.9,1,.18));floor.y=p.y-54;s.field.add(floor);
   const st={seat:s,rand:this.newRand(),beam:new Node(),ball:new Sprite(Gfx.ball(BALLR),BALLR*2,BALLR*2),wind:label('',s.w>300?22:16,rgba(.6,.9,1)),s:0,v:0,theta:0,target:0,touchX:{},gustTimer:1.5,gustLeft:0,gust:0,alive:0,cpuTimer:0};
   st.beam.x=p.x;st.beam.y=p.y;st.beam.z=5;
   const shaft=new Sprite(null,L,10,white(.95));st.beam.add(shaft);const tape=new Sprite(null,L*.18,10,s.color);tape.x=-L/2+L*.09;tape.z=1;st.beam.add(tape);
   const blade=new Sprite(null,10,22,s.color);blade.x=L/2-5;blade.y=-6;blade.z=1;st.beam.add(blade);const mid=new Sprite(null,4,12,Theme.orange);mid.z=2;st.beam.add(mid);
   s.field.add(st.beam);st.ball.z=8;s.field.add(st.ball);const glow=new Sprite(Gfx.glow(),50,50);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.5;glow.z=-1;st.ball.add(glow);
   st.wind.y=s.h*.22;st.wind.z=20;s.field.add(st.wind);
   for(const[sign,txt]of[[-1,'◀︎'],[1,'▶︎']]){const l=label(txt,28,s.color);l.alpha=.35;l.x=sign*s.w*.36;l.y=-s.h*.36;s.field.add(l)}
   const hint=label(s.isCPU?'CPU':'LINKS / RECHTS HALTEN',s.w>300?17:12,white(1,.85));hint.y=s.h*.12;hint.z=40;s.field.add(hint);hint.run(A.sequence([A.wait(4.6),A.fadeOut(.4),A.remove()]));
   this.states.push(st);this.place(st)}}
 place(st){const p=this.pivot(st.seat),c=Math.cos(st.theta),sn=Math.sin(st.theta),off=BALLR+BEAMT/2;st.ball.x=p.x+c*st.s-sn*off;st.ball.y=p.y+sn*st.s+c*off;st.ball.rot=-st.s/BALLR;st.beam.rot=st.theta}
 gameUpdate(dt){const t=this.elapsed;
  for(const st of this.states){const s=st.seat;if(!s.alive)continue;st.gustTimer-=dt;
   if(st.gustTimer<=0){st.gustTimer=st.rand.range(1.3,2.6);st.gustLeft=.8;st.gust=st.rand.range(-1,1)*(45+t*4.5);st.wind.text=st.gust<0?'💨 ◀︎◀︎':'▶︎▶︎ 💨';st.wind.alpha=1;st.wind.run(A.sequence([A.wait(.6),A.fadeOut(.3)]))}
   let g=0;if(st.gustLeft>0){st.gustLeft-=dt;g=st.gust}
   if(s.isCPU)this.cpuThink(st,dt,g);else{const xs=Object.values(st.touchX);if(xs.length)st.target=Math.max(-1,Math.min(1,-xs[0]/(s.w*.35)))*MAXTILT;else st.target=0}
   const step=2*dt;st.theta+=Math.max(-step,Math.min(step,st.target-st.theta));
   const c=.6+t*.05,a=-G*Math.sin(st.theta)+c*st.s+g;st.v+=a*dt;st.v*=(1-.3*dt);st.s+=st.v*dt;this.place(st);
   if(Math.abs(st.s)>this.beamL(s)/2+2){this.drop(st);continue}
   st.alive+=dt;const sc=Math.floor(st.alive*10);if(sc!==s.score){s.score=sc;if(s.scoreLabel)s.scoreLabel.text=''+sc}}
  this.checkEnd()}
 cpuThink(st,dt,gust){st.cpuTimer-=dt;if(st.cpuTimer>0)return;const s=st.seat;st.cpuTimer=.06+(1-s.skill)*.25;const c=.6+this.elapsed*.05,kp=3,kd=2.5;
  let sn=(c*st.s+kp*st.s+kd*st.v+gust*s.skill)/G;sn+=(Math.random()*2-1)*(1-s.skill)*.12;sn=Math.max(-.99,Math.min(.99,sn));st.target=Math.max(-MAXTILT,Math.min(MAXTILT,Math.asin(sn)))}
 drop(st){const s=st.seat,dir=st.s>0?1:-1;st.ball.run(A.group([A.moveBy(dir*30,-s.h*.6,.7),A.fadeOut(.7)]));s.knockOut('RUNTER');Sfx.play('miss');if(!s.isCPU)Haptic.bad()}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others)this.finishGame()}}
 began(seat,at,id){const st=this.states.find(s=>s.seat===seat);if(st)st.touchX[id]=at.x}
 moved(seat,at,id){const st=this.states.find(s=>s.seat===seat);if(st)st.touchX[id]=at.x}
 ended(seat,at,id){const st=this.states.find(s=>s.seat===seat);if(st)delete st.touchX[id]}
}
Arcade.register('balance',BalanceGame);
})();
