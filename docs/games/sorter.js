(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const COLS=[Theme.orange,rgba(.2,.55,1)];
const BALLR=14;
class SorterGame extends MiniScene{
 yStart(s){return s.h/2-44}yMouth(s){return -s.h/2+66}basketX(s,side){return(side===0?-1:1)*s.w*.27}
 setupGame(){this.duration=30;this.states=[];
  for(const s of this.seats){const bear=this.makeBear(s,36,false),st={seat:s,rand:this.newRand(),bear,baskets:[],ball:null,color:0,y:0,age:0,wait:.2,cpuDelay:0,cpuSide:0,streak:0};
   const div=new Sprite(null,2,s.h-60,white(1,.12));div.y=-4;div.z=1;s.field.add(div);
   for(let side=0;side<2;side++){const bw=s.w*.36,b=new Sprite(Gfx.pill(bw,40,rgba(...CC[side],.35),COLS[side],10,false),bw,40);b.x=this.basketX(s,side);b.y=-s.h/2+32;b.z=3;
    const g=new Sprite(Gfx.glow(),bw*1.6,70);g.color=COLS[side];g.cbf=1;g.blend='add';g.alpha=.5;g.z=-1;b.add(g);s.field.add(b);st.baskets.push(b);
    const ar=label(side===0?'◀':'▶',14,white(1,.8));ar.z=1;b.add(ar)}
   bear.x=0;bear.y=-s.h/2+8;bear.z=4;s.field.add(bear);bear.startBob(3,.3);
   const hint=label(s.isCPU?'CPU':'◀ ORANGE · BLAU ▶',s.w>300?17:12,white(1,.85));hint.z=30;s.field.add(hint);hint.run(A.sequence([A.wait(4.7),A.fadeOut(.4),A.remove()]));
   this.states.push(st)}}
 get fallSpeed(){return(120+this.elapsed*8)*(this.seats.length?this.seats[0].h/370:1)}
 spawn(st){const s=st.seat;st.color=st.rand.chance(.5)?1:0;const n=new Node();
  n.add(new Sprite(Gfx.circle(BALLR,COLS[st.color],white(1,.9)),BALLR*2,BALLR*2));
  const g=new Sprite(Gfx.glow(),BALLR*5,BALLR*5);g.color=COLS[st.color];g.cbf=1;g.blend='add';g.alpha=.8;g.z=-1;n.add(g);n.z=10;
  st.y=this.yStart(s);n.x=0;n.y=st.y;s.field.add(n);st.ball=n;st.age=0;
  const fall=(this.yStart(s)-this.yMouth(s))/this.fallSpeed;
  st.cpuDelay=(.18+(1-s.skill)*.55+Math.random()*.12)*Math.min(1,fall/.9);
  st.cpuSide=Math.random()<(1-s.skill)*.28?1-st.color:st.color}
 decide(st,side){if(!st.ball||!st.seat.alive||this.phase!=='playing')return;const s=st.seat,ball=st.ball;st.ball=null;st.wait=.15;const ok=side===st.color,tgt={x:this.basketX(s,side),y:this.yMouth(s)-8};
  ball.run(A.sequence([A.group([A.moveTo(tgt.x,tgt.y,.1),A.scaleTo(.6,.1)]),A.remove()]));
  st.baskets[side].run(A.sequence([A.scaleTo(1.12,.05),A.scaleTo(1,.1)]));
  if(ok){st.streak++;this.addScore(s,1);this.addStat('balls',1,s);s.floatText('+1',{x:tgt.x,y:tgt.y+30},COLS[side],20);s.burst(tgt,COLS[side],8,90);st.bear.squash();
   if(st.streak%5===0){st.bear.celebrate();s.floatText(st.streak+'er SERIE!',{x:0,y:20},'#ff0',16)}
   if(!s.isCPU){Sfx.play('pop');Haptic.tap()}}
  else{st.streak=0;this.addScore(s,-1);s.floatText('-1',{x:tgt.x,y:tgt.y+30},'#f33',22);s.flash('#f00',.25,.25);s.shake(3);if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}}}
 miss(st){if(!st.ball)return;const s=st.seat,ball=st.ball;st.ball=null;st.wait=.25;st.streak=0;ball.run(A.sequence([A.fadeOut(.15),A.remove()]));this.addScore(s,-1);s.floatText('ZU LANGSAM',{x:0,y:this.yMouth(s)+20},'#f33',14);if(!s.isCPU){Sfx.play('miss');Haptic.bad()}}
 gameUpdate(dt){for(const st of this.states){if(st.ball){st.age+=dt;st.y-=this.fallSpeed*dt;st.ball.y=st.y;if(st.seat.isCPU&&st.age>=st.cpuDelay)this.decide(st,st.cpuSide);else if(st.y<=this.yMouth(st.seat))this.miss(st)}else{st.wait-=dt;if(st.wait<=0)this.spawn(st)}}}
 began(seat,at){const st=this.states.find(s=>s.seat===seat);if(st)this.decide(st,at.x<0?0:1)}
}
const CC=[[1,.54,0],[.2,.55,1]];
Arcade.register('sorter',SorterGame);
})();
