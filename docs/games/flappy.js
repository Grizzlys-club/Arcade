(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const GRAV=-950,FLAP=300,GW=26,BR=12,BH=30;
class FlappyGame extends MiniScene{
 yTop(s){return s.h/2-32}yBot(s){return -s.h/2+10}bx(s){return -s.w*.25}
 setupGame(){this.duration=60;this.states=[];
  for(const s of this.seats){const bear=this.makeBear(s,BH,true),st={seat:s,rand:this.newRand(),bear,layer:new Node(),y:0,vy:0,gates:[],nextSpawn:70,cpuCooldown:0,cpuNoise:0,cpuGate:null};s.field.add(st.layer);st.layer.z=5;
   for(const yy of[this.yBot(s),this.yTop(s)]){const line=new Sprite(null,s.w,3,s.color);line.alpha=.6;line.y=yy;line.z=2;s.field.add(line);const glow=new Sprite(Gfx.glow(),s.w*1.2,26);glow.color=s.color;glow.cbf=1;glow.alpha=.35;glow.blend='add';glow.y=yy;glow.z=1;s.field.add(glow)}
   for(let i=0;i<10;i++){const d=new Sprite(Gfx.dot(),4,4);d.alpha=.25;d.x=i*s.w/10-s.w/2;d.y=this.yBot(s)+Math.random()*(this.yTop(s)-this.yBot(s));d.z=0;s.field.add(d);const dur=4+Math.random()*4;d.run(A.forever(A.sequence([A.moveBy(-s.w-20,0,dur),A.moveBy(s.w+20,0,0)])))}
   st.y=0;bear.x=this.bx(s);bear.y=st.y-BH/2;bear.z=20;s.field.add(bear);bear.startBob(4,.3);
   const hint=label(s.isCPU?'CPU':'TIPPEN = FLATTERN',s.w>300?18:13,white(1,.8));hint.y=-s.h*.25;hint.z=30;s.field.add(hint);st.hint=hint;this.states.push(st)}}
 gameStarted(){for(const st of this.states){st.bear.stopBob();st.vy=FLAP*.6;st.hint.run(A.sequence([A.wait(1.5),A.fadeOut(.4),A.remove()]))}}
 get scrollSpeed(){const w=this.seats.length?this.seats[0].w:390;return(95+this.elapsed*2)*(.72+.28*w/390)}
 spacing(s){return Math.max(135,s.w*.55)}
 spawnGate(st){const s=st.seat,gap=Math.max(92,138-this.elapsed*.75),lo=this.yBot(s)+gap/2+16,hi=this.yTop(s)-gap/2-16,gy=st.rand.range(lo,Math.max(lo,hi)),g={node:new Node(),x:s.w/2+GW,gapY:gy,gap,passed:false};
  const botH=(gy-gap/2)-this.yBot(s),topH=this.yTop(s)-(gy+gap/2);
  for(const[hgt,cy,capY]of[[botH,this.yBot(s)+botH/2,gy-gap/2],[topH,this.yTop(s)-topH/2,gy+gap/2]]){if(hgt<=0)continue;
   const board=new Sprite(null,GW,hgt,white(.93));board.y=cy;g.node.add(board);const stripe=new Sprite(null,5,hgt,rgba(1,.54,0,.9));stripe.y=cy;stripe.z=1;g.node.add(stripe);
   const cap=new Sprite(null,GW+8,8,s.color);cap.y=capY;cap.z=2;g.node.add(cap);const glow=new Sprite(Gfx.glow(),GW+40,30);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.6;glow.y=capY;glow.z=3;g.node.add(glow)}
  g.node.x=g.x;g.node.y=0;st.layer.add(g.node);st.gates.push(g)}
 flap(st){if(!st.seat.alive||this.phase!=='playing')return;st.vy=FLAP;st.bear.squash();if(!st.seat.isCPU){Sfx.play('jump');Haptic.tap()}}
 crash(st){const s=st.seat;if(!s.alive)return;s.knockOut('ABSTURZ');s.shake(6);s.burst({x:this.bx(s),y:st.y},s.color,14);Sfx.play('hit');if(!s.isCPU)Haptic.bad();st.bear.run(A.group([A.moveBy(0,-s.h,.8),A.rotateBy(-3,.8)]))}
 gameUpdate(dt){const dist=this.scrollSpeed*dt;
  for(const st of this.states){const s=st.seat;for(const g of st.gates){g.x-=dist;g.node.x=g.x}
   while(st.gates.length&&st.gates[0].x<-s.w/2-GW*2){st.gates[0].node.removeFromParent();st.gates.shift()}
   if(!s.alive)continue;st.nextSpawn-=dist;if(st.nextSpawn<=0){st.nextSpawn+=this.spacing(s);this.spawnGate(st)}
   if(s.isCPU)this.cpuThink(st,dt);st.vy+=GRAV*dt;st.y+=st.vy*dt;if(st.y+BR>this.yTop(s)){st.y=this.yTop(s)-BR;st.vy=Math.min(0,st.vy)}
   st.bear.x=this.bx(s);st.bear.y=st.y-BH/2;st.bear.rot=Math.max(-.6,Math.min(.45,st.vy/650));
   if(st.y-BR<this.yBot(s)){this.crash(st);continue}
   const bx=this.bx(s);
   for(const g of st.gates){if(Math.abs(g.x-bx)<GW/2+BR-2){if(st.y-BR+3<g.gapY-g.gap/2||st.y+BR-3>g.gapY+g.gap/2){this.crash(st);break}}
    if(!g.passed&&g.x+GW/2<bx-BR){g.passed=true;this.addScore(s,1);s.floatText('+1',{x:bx,y:st.y+24},s.color,18);if(!s.isCPU)Sfx.play('pop')}}}
  this.checkEnd()}
 cpuThink(st,dt){st.cpuCooldown-=dt;const s=st.seat,bx=this.bx(s),next=st.gates.find(g=>g.x+GW/2>bx-BR);let target;
  if(next){if(st.cpuGate!==next){st.cpuGate=next;st.cpuNoise=(Math.random()*2-1)*(1-s.skill)*next.gap*.55}target=next.gapY-next.gap/2+BR+12+st.cpuNoise*.3}else target=0;
  const predicted=st.y+st.vy*.1+.5*GRAV*.01;
  if(predicted<target&&st.cpuCooldown<=0){if(Math.random()<(1-s.skill)*.012){st.cpuCooldown=.3;return}st.cpuCooldown=.12+(1-s.skill)*.08;this.flap(st)}}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others)this.finishGame()}}
 began(seat){const st=this.states.find(s=>s.seat===seat);if(st)this.flap(st)}
}
Arcade.register('flappy',FlappyGame);
})();
