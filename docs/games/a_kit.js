(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
window.NK={
 icon(name,size){size=Math.round(size);const OL='#1b1b24';return new Sprite(Gfx.texture('ico_'+name+size,size,size,3,c=>{c.scale(size/100,size/100);c.lineJoin='round';c.lineCap='round';
  const rr=(x,y,w,h,r)=>{c.beginPath();c.moveTo(x+r,y);c.arcTo(x+w,y,x+w,y+h,r);c.arcTo(x+w,y+h,x,y+h,r);c.arcTo(x,y+h,x,y,r);c.arcTo(x,y,x+w,y,r);c.closePath()};
  const fs=(f,w)=>{c.fillStyle=f;c.fill();c.strokeStyle=OL;c.lineWidth=w||3.5;c.stroke()};
  if(name==='stick'){c.strokeStyle=OL;c.lineWidth=11;c.beginPath();c.moveTo(24,84);c.lineTo(72,12);c.stroke();c.strokeStyle='#3a3f4d';c.lineWidth=6;c.beginPath();c.moveTo(24,84);c.lineTo(72,12);c.stroke();
   c.strokeStyle=OL;c.lineWidth=11;c.beginPath();c.moveTo(61,29);c.lineTo(73,11);c.stroke();c.strokeStyle='#ff6a00';c.lineWidth=6;c.beginPath();c.moveTo(61,29);c.lineTo(73,11);c.stroke();
   c.beginPath();c.moveTo(10,76);c.lineTo(40,86);c.quadraticCurveTo(46,90,40,95);c.lineTo(12,92);c.quadraticCurveTo(4,86,10,76);c.closePath();fs('#ff6a00',3.5)}
  else if(name==='ball'){c.beginPath();c.arc(50,52,33,0,7);fs('#ffffff',4);c.fillStyle=OL;[[50,52],[50,36],[50,68],[36,44],[64,44],[36,60],[64,60]].forEach(([x,y])=>{c.beginPath();c.arc(x,y,5,0,7);c.fill()});c.fillStyle='rgba(255,255,255,.9)';c.beginPath();c.arc(40,34,4,0,7);c.fill()}
  else if(name==='glove'){[[30,16],[41,10],[52,10],[63,16]].forEach(([x,y],i)=>{rr(x,y,10,40,5);fs('#f4f4f6',3)});rr(24,40,52,40,12);fs('#f4f4f6',3.5);c.save();c.translate(24,60);c.rotate(-.7);rr(-6,-6,32,12,6);fs('#f4f4f6',3);c.restore();rr(26,76,48,16,5);fs('#ff6a00',3.5);c.strokeStyle='rgba(0,0,0,.18)';c.lineWidth=2;[48,58,68].forEach(y=>{c.beginPath();c.moveTo(36,y);c.lineTo(66,y);c.stroke()})}
  else if(name==='goal'){c.fillStyle='rgba(255,255,255,.12)';c.fillRect(14,28,72,50);c.strokeStyle='rgba(40,40,55,.55)';c.lineWidth=1.6;for(let x=14;x<=86;x+=9){c.beginPath();c.moveTo(x,28);c.lineTo(x,78);c.stroke()}for(let y=28;y<=78;y+=8.3){c.beginPath();c.moveTo(14,y);c.lineTo(86,y);c.stroke()}
   c.strokeStyle=OL;c.lineWidth=11;c.beginPath();c.moveTo(14,80);c.lineTo(14,26);c.lineTo(86,26);c.lineTo(86,80);c.stroke();c.strokeStyle='#e8242c';c.lineWidth=6.5;c.beginPath();c.moveTo(14,80);c.lineTo(14,26);c.lineTo(86,26);c.lineTo(86,80);c.stroke()}
  else if(name==='trophy'){c.lineWidth=4;c.strokeStyle=OL;[[28,26,-1],[72,26,1]].forEach(([x,y,d])=>{c.beginPath();c.moveTo(x,y);c.bezierCurveTo(x+d*20,y-2,x+d*20,y+24,x+d*4,y+26);c.stroke()});
   c.beginPath();c.moveTo(27,14);c.lineTo(73,14);c.lineTo(71,40);c.quadraticCurveTo(66,62,50,62);c.quadraticCurveTo(34,62,29,40);c.closePath();fs('#f2b92d',4);c.fillStyle='rgba(255,255,255,.45)';c.beginPath();c.ellipse(38,30,4,12,.1,0,7);c.fill();
   rr(45,60,10,16,2);fs('#d79a17',3.5);rr(30,76,40,12,4);fs('#f2b92d',3.5)}
 },size),size,size)},
 al:(c,a)=>c.replace(/[\d.]+\)$/,a+')'),
 rr:(a,b)=>a+Math.random()*(b-a),
 pf(s){return{w:s.w-16,h:s.h-80,cy:-6}},
 panel(s,col){const p=NK.pf(s),sp=new Sprite(Gfx.pill(p.w,p.h,'rgba(10,12,26,.55)',NK.al(col,.4),22,false),p.w,p.h);sp.y=p.cy;sp.z=-5;s.field.add(sp);const g=new Sprite(Gfx.glow(),p.w*1.2,p.h*1.1);g.color=col;g.cbf=1;g.blend='add';g.alpha=.1;g.y=p.cy;g.z=-6;s.field.add(g);return p},
 ring(s,pos,col,r,dur){const g=new Sprite(Gfx.circle(r||14,'rgba(0,0,0,0)',col),(r||14)*2,(r||14)*2);g.blend='add';g.x=pos.x;g.y=pos.y;g.z=50;s.field.add(g);g.run(A.sequence([A.group([A.scaleTo(3,dur||.35),A.fadeOut(dur||.35)]),A.remove()]))},
 dot(s,col,w,z){const d=new Sprite(Gfx.dot(),w,w);d.color=col;d.cbf=1;d.blend='add';d.z=z||10;s.field.add(d);return d},
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v))
};})();
